require "application_system_test_case"

class OrderFlowTest < ApplicationSystemTestCase
  let(:order) { create(:order) }

  describe "new order page" do
    let(:order_create_attributes) do
      %i[email_address first_name last_name street_line_1 street_line_2 postal_code city region]
    end
    let(:country) { ISO3166::Country[Faker::Address.country_code].to_s }
    let(:valid_order_hash) do
      attributes_for(:order)
        .select do |k, _v|
          order_create_attributes.include?(k)
        end
    end
    let(:order_hash) { valid_order_hash }

    before { visit root_url }

    it "contains valid header" do
      assert_selector "h1", text: "New Order"
    end

    it "allows order creation" do
      order_hash.each_pair do |k, v|
        fill_in k.to_s.humanize, with: v
      end
      select country, from: "Country"

      assert_difference("Order.count", 1) do
        click_on "Create Order"
      end

      assert_selector "h1", text: "Pay"

      assert_text "Order was successfully created"

      order_hash.each_pair do |k, v|
        assert_equal v, Order.last[k]
      end
    end
  end

  describe "payment page" do
    let(:order) { create(:order) }

    before { visit order_pay_url(permalink: order.permalink) }

    it "contains valid header" do
      assert_selector "h1", text: "Pay"
    end

    it "requires card details" do
      click_button id: "pay"

      assert_text "Your card number is incomplete"
    end

    it "allows payment" do
      fill_stripe_elements(card: "4242424242424242")

      click_button id: "pay"

      assert_text "New order"
      assert_text "Amount paid"
      assert_text "Paid at"
    end

    it "handles SCA pass" do
      fill_stripe_elements(card: "4000002500003155")

      click_button id: "pay"

      complete_stripe_sca

      assert_text "New order"
      assert_text "Amount paid"
      assert_text "Paid at"
    end

    it "handles SCA failure" do
      fill_stripe_elements(card: "4000002500003155")

      click_button id: "pay"

      fail_stripe_sca

      assert_selector "h1", text: "Pay"
      assert_text "We are unable to authenticate your payment method"
    end

    it "handles card declines" do
      fill_stripe_elements(card: "4000000000009995")

      click_button id: "pay"

      assert_selector "h1", text: "Pay"
      assert_text "Your card has insufficient funds"
    end
  end
end
