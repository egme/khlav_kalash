class OrdersController < ApplicationController
  include HttpBasicAuthenticatable

  before_action :http_authenticate, except: [:new, :create, :pay, :permalink]
  before_action :set_order_by_id, only: [:show, :edit, :update, :destroy]
  before_action :set_order_by_permalink, only: [:pay, :permalink]

  def new
    @order = Order.new
  end

  def create
    @order = Order.new(order_params)

    if @order.save
      redirect_to order_pay_url(@order.permalink), notice: "Order was successfully created."
    else
      render :new
    end
  end

  def pay
    @intent = StripePayments.retrieve_intent(@order.payment_intent_id)

    return unless @intent.status == "succeeded"

    redirect_to order_permalink_url(@order.permalink), notice: "Order was successfully paid."
  rescue StripePayments::APIError => e
    render status: :service_unavailable, body: "Error retrieving payment info #{e.message}"
  end

  def permalink
    return if order_paid?

    redirect_to order_pay_url(@order.permalink), notice: "Order is not paid yet."
  rescue StripePayments::APIError => e
    render status: :service_unavailable, body: "Error retrieving payment info #{e.message}"
  end

  def index
    @orders = Order.all
  end

  def show
  end

  def edit
  end

  def update
    if @order.update(order_params)
      redirect_to @order, notice: "Order was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @order.destroy

    redirect_to orders_url, notice: "Order was successfully destroyed."
  end

  private

  def set_order_by_id
    @order = Order.find(params[:id])
  end

  def set_order_by_permalink
    @order = Order.find_by(permalink: params[:permalink])
  end

  def order_paid?
    return true if @order.paid_at

    @intent = StripePayments.retrieve_intent(@order.payment_intent_id)

    if @intent.status == "succeeded" && @intent.paid_at
      @order.update(paid_at: @intent.paid_at)
      return true
    end

    false
  end

  def order_params
    params
      .require(:order)
      .permit(
        :email_address, :first_name, :last_name,
        :street_line_1, :street_line_2, :postal_code, :city, :region, :country
      )
  end
end
