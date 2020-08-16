require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  def self.it_is_protected_with_basic_auth(expected_response: :ok)
    describe "without basic auth" do
      let(:admin_auth_headers) { {} }

      it "responds with 401" do
        assert_response :unauthorized
      end
    end

    describe "with proper authentication" do
      it "responds with #{expected_response}" do
        assert_response expected_response
      end
    end
  end

  describe "admin area" do
    let(:admin_auth_headers) do
      { Authorization: ActionController::HttpAuthentication::Basic.encode_credentials("admin", "password") }
    end
    let(:order) { create(:order) }
    let(:orders) { create_list(:order, 3) }

    describe "GET /orders" do
      let(:request) { get orders_url, headers: admin_auth_headers }

      before do
        orders
        request
      end

      it_is_protected_with_basic_auth

      it "renders all orders" do
        orders.each do |order|
          assert_includes response.body, order.permalink
        end
      end
    end

    describe "GET /orders/:id" do
      let(:request) { get order_url(order), headers: admin_auth_headers }

      before { request }

      it_is_protected_with_basic_auth

      it "renders all order fields" do
        %i[amount_cents first_name last_name country email_address number permalink]
          .map { |field| CGI.escapeHTML(order.send(field).to_s) }
          .push(edit_order_path(order))
          .each do |field|
            assert_includes response.body, field
          end
      end
    end

    describe "GET /orders/:id/edit" do
      let(:request) { get edit_order_url(order), headers: admin_auth_headers }

      before { request }

      it_is_protected_with_basic_auth

      it "renders order fields" do
        %i[number permalink first_name last_name street_line_1 street_line_2 postal_code city region email_address]
          .map { |field| CGI.escapeHTML(order.send(field).to_s) }
          .push(order.paid_at.try(:utc).try(:iso8601).to_s)
          .push(order_path(order))
          .push(orders_path)
          .each do |field|
            assert_includes response.body, field
          end
      end

    end

    describe "PATCH/PUT /orders/:id" do
      let(:new_order_attributes) do
        %i[first_name last_name street_line_1 street_line_2 postal_code city region country email_address]
      end
      let(:valid_order_hash) do
        attributes_for(:order)
          .select do |k, _v|
            new_order_attributes.include?(k)
          end
      end
      let(:order_hash) { valid_order_hash }
      let(:request) do
        patch(
          order_url(order),
          params: {
            order: order_hash
          },
          headers: admin_auth_headers
        )
      end

      before { request }

      it_is_protected_with_basic_auth(expected_response: 302)

      describe "with valid data" do
        it "redirects to order" do
          assert_redirected_to order_url(order)
        end

        it "updates order attributes" do
          order_hash.each_pair do |attr, val|
            assert_equal val, order.reload[attr]
          end
        end
      end

      describe "with invalid data" do
        let(:missing_attribute) { %i[email_address first_name postal_code country].sample }
        let(:order_hash) { valid_order_hash.merge(missing_attribute => "") }

        it "does not redirect" do
          assert_response :ok
        end

        it "renders error message" do
          assert_includes response.body, "Order cannot be saved"
          assert_includes response.body, CGI.escapeHTML("#{missing_attribute.to_s.humanize} can't be blank")
        end

        it "prefills entered values" do
          order_hash
            .reject { |k, _v| k == :country }
            .each_value do |attr|
              assert_includes response.body, CGI.escapeHTML(attr)
            end
        end

        it "does not change order attributes" do
          new_order_attributes.each do |attr|
            assert_equal order[attr], order.reload[attr]
          end
        end
      end
    end

    describe "DELETE /orders/:id" do
      let(:request) { delete order_url(order), headers: admin_auth_headers }

      describe "authentication" do
        before { request }

        it_is_protected_with_basic_auth(expected_response: 302)
      end

      it "destroys order" do
        order
        assert_difference("Order.count", -1) { request }
      end

      it "redirects to orders list" do
        request
        assert_redirected_to orders_url
      end
    end
  end

  describe "order flow" do
    describe "GET /" do
      it "responds with 200" do
        get new_order_url
        assert_response :success
      end
    end

    describe "POST /orders" do
      let(:order_create_attributes) do
        %i[email_address first_name last_name street_line_1 street_line_2 postal_code city region country]
      end
      let(:valid_order_hash) do
        attributes_for(:order)
          .select do |k, _v|
            order_create_attributes.include?(k)
          end
      end
      let(:order_hash) { valid_order_hash }
      let(:request) { post(orders_url, params: { order: order_hash }) }
      let(:order) { Order.last }

      describe "with valid data" do
        before { request }

        it "creates order" do
          assert_equal 1, Order.count
        end

        it "sets all submitted order fields" do
          order_hash.each_pair do |k, v|
            assert_equal v, order[k]
          end
        end

        it "sets permalink" do
          assert_not_empty order.permalink
        end

        it "sets number" do
          assert_not_empty order.number
        end

        it "performs Stripe API call" do
          assert_requested :post, StripeServer::INTENTS_URL
        end

        it "sets payment_intent_id" do
          assert_not_empty order.payment_intent_id
        end

        it "redirects to payment page" do
          assert_redirected_to order_pay_url(Order.last.permalink)
        end

        it "stores flash message" do
          assert_equal "Order was successfully created.", flash[:notice]
        end
      end

      describe "with invalid data" do
        let(:missing_attribute) { %i[email_address first_name postal_code country].sample }
        let(:order_hash) { valid_order_hash.reject { |k, _v| k == missing_attribute } }

        before { request }

        it "does not create order" do
          assert Order.count.zero?
        end

        it "does not perform Stripe API call" do
          assert_not_requested :post, StripeServer::INTENTS_URL
        end

        it "does not redirect" do
          assert_response :ok
        end

        it "renders order form" do
          assert_includes response.body, "New Order"
        end

        it "renders error message" do
          assert_includes response.body, "Order cannot be saved"
          assert_includes response.body, CGI.escapeHTML("#{missing_attribute.to_s.humanize} can't be blank")
        end

        it "prefills entered values" do
          order_hash
            .reject { |k, _v| k == :country }
            .each_value do |attr|
              assert_includes response.body, CGI.escapeHTML(attr)
            end
        end
      end

      describe "with broken stripe server" do
        before do
          StripeServer.break
          request
        end

        it "does not create order" do
          assert Order.count.zero?
        end

        it "performs Stripe API call" do
          assert_requested :post, StripeServer::INTENTS_URL
        end

        it "does not redirect" do
          assert_response :ok
        end

        it "renders order form" do
          assert_includes response.body, "New Order"
        end

        it "renders error message" do
          assert_includes response.body, "Order cannot be saved"
          assert_includes response.body, "Unable to prepare payment"
        end

        it "prefills entered values" do
          order_hash
            .reject { |k, _v| k == :country }
            .each_value do |attr|
              assert_includes response.body, CGI.escapeHTML(attr)
            end
        end
      end
    end

    describe "GET /pay/:permalink" do
      let(:order) { create(:order) }
      let(:request) { get order_pay_url(order.permalink) }

      before { order }

      it "performs Stripe API call" do
        request
        assert_requested :get, StripeServer.intent_url_template
      end

      describe "with not paid order" do
        before { request }

        it "responds with 200" do
          assert_response :ok
        end

        it "renders Stripe public key" do
          assert_includes response.body, ENV.fetch("STRIPE_PUBLIC_KEY")
        end

        it "renders intent client secret" do
          assert_includes response.body, StripeServer.intents.last[:client_secret]
        end

        it "renders order permalink" do
          assert_includes response.body, order.permalink
        end

        it "renders billing details hash" do
          assert_includes response.body, order.billing_details_hash.to_json
        end

        it "renders price" do
          assert_includes response.body, order.price.format
        end
      end

      describe "with paid order" do
        let(:paid_intent) { StripeServer.create_intent(:succeeded) }
        let(:order) { create(:order, payment_intent_id: paid_intent[:id]) }

        before { request }

        it "redirects to permalink url" do
          assert_redirected_to order_permalink_url(order.permalink)
        end

        it "stores flash message" do
          assert_equal "Order was successfully paid.", flash[:notice]
        end
      end

      describe "with broken API" do
        before do
          StripeServer.break
          request
        end

        it "responds with 503" do
          assert_response :service_unavailable
        end

        it "renders error message" do
          assert_includes response.body, "Error retrieving payment info"
        end
      end
    end

    describe "GET /order/:permalink" do
      let(:paid_intent) { StripeServer.create_intent(:succeeded) }
      let(:order) { create(:order, payment_intent_id: paid_intent[:id]) }
      let(:request) { get order_permalink_url(order.permalink) }

      before { order }

      it "performs Stripe API call" do
        request
        assert_requested :get, StripeServer.intent_url_template
      end

      describe "with paid order" do
        before { request }

        it "responds with 200" do
          assert_response :ok
        end

        it "renders order details" do
          %i[number first_name last_name street_line_1 street_line_2 postal_code city country email_address].each do |field|
            assert_includes response.body, CGI.escapeHTML(order[field])
          end
        end

        it "renders price" do
          assert_includes response.body, order.price.format
        end

        it "renders link to new order" do
          assert_includes response.body, root_path
        end

        it "records payment timestamp" do
          assert_not_nil order.reload.paid_at
        end

        it "renders payment timestamp" do
          assert_includes response.body, order.reload.paid_at.utc.iso8601
        end

        describe "with recorded payment timestamp" do
          let(:order) { create(:order, payment_intent_id: paid_intent[:id], paid_at: Time.current) }

          it "does not perform Stripe API call" do
            assert_not_requested :get, StripeServer.intent_url_template
          end
        end
      end

      describe "with not paid order" do
        let(:order) { create(:order) }

        before { request }

        it "redirects to pay url" do
          assert_redirected_to order_pay_url(order.permalink)
        end

        it "stores flash message" do
          assert_equal "Order is not paid yet.", flash[:notice]
        end
      end

      describe "with broken API" do
        before do
          StripeServer.break
          request
        end

        it "responds with 503" do
          assert_response :service_unavailable
        end

        it "renders error message" do
          assert_includes response.body, "Error retrieving payment info"
        end
      end
    end
  end
end
