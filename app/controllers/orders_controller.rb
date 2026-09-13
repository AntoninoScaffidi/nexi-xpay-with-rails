class OrdersController < ApplicationController
  before_action :set_product, only: [ :new, :create ]

  def new
    redirect_to(product_path(@product)) and return unless @product.purchasable?

    @order = Order.new
  end

  def create
    redirect_to(product_path(@product)) and return unless @product.purchasable?

    @order = Order.build_from_product!(
      product: @product,
      guest_attributes: order_params.to_h,
      quantity: order_params[:quantity].presence || 1
    )

    gateway = Nexi::Gateway.new
    @payment_form_url = gateway.payment_form_url
    @payment_params = gateway.build_payment_params(
      @order,
      return_url: nexi_return_url,
      cancel_url: nexi_return_url,
      notify_url: nexi_notify_url
    )
  rescue ActiveRecord::RecordInvalid => e
    @order = e.record
    render :new, status: :unprocessable_entity
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def order_params
    params.permit(:quantity, :guest_first_name, :guest_last_name, :guest_email, :guest_phone)
  end
end
