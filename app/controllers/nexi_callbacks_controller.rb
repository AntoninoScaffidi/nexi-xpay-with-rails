class NexiCallbacksController < ActionController::Base
  skip_before_action :verify_authenticity_token, only: [ :notify ]

  def notify
    order = Order.find_by(order_number: params[:codTrans])

    if order.nil?
      Rails.logger.error("[Nexi] Notification for unknown codTrans: #{params[:codTrans]}")
      head :ok and return
    end

    notification = order.order_payment_notifications.create!(raw_params: raw_notification_params)

    gateway = Nexi::Gateway.new
    mac_valid = gateway.verify_mac(raw_notification_params)
    notification.update!(mac_verified: mac_valid)

    unless mac_valid
      notification.update!(processed: true, outcome: "invalid_mac")
      Rails.logger.error("[Nexi] Invalid MAC on notification for order #{order.order_number}")
      head :ok and return
    end

    case params[:esito]
    when "OK"
      if order.pending_payment?
        order.mark_paid!(
          nexi_transaction_id: params[:codTrans],
          nexi_authorization_code: params[:codAut],
          nexi_raw_response: raw_notification_params
        )
        notification.update!(processed: true, outcome: "paid")
      else
        notification.update!(processed: true, outcome: "duplicate") # idempotency
      end
    else
      order.update!(status: :payment_failed) if order.pending_payment?
      notification.update!(processed: true, outcome: params[:esito].to_s.downcase.presence || "unknown")
    end

    head :ok
  end

  def return
    order = Order.find_by(order_number: params[:codTrans])

    if order.nil?
      redirect_to root_path
      return
    end

    redirect_to order_path(order)
  end

  private

  # Not mass assignment onto an ActiveRecord model: this only captures
  # Nexi's raw payload for the OrderPaymentNotification audit log.
  def raw_notification_params
    params.to_unsafe_h.except("controller", "action")
  end
end
