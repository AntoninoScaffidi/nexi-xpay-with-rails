require "test_helper"

class NexiCallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @order = orders(:pending_order) # codTrans: TESTORDER001, importo (cents): 3500
    @mac_key = Rails.application.credentials.dig(:nexi, :sandbox, :mac_key)
  end

  test "a valid OK notification marks the order paid" do
    post nexi_notify_path, params: notification_params(esito: "OK")

    assert_response :ok
    assert @order.reload.paid?
    assert_equal "MP7EL4", @order.nexi_authorization_code
  end

  test "the same notification received twice does not double-process" do
    post nexi_notify_path, params: notification_params(esito: "OK")
    post nexi_notify_path, params: notification_params(esito: "OK")

    assert_equal 2, @order.order_payment_notifications.count
    assert_equal 1, @order.order_payment_notifications.where(outcome: "paid").count
    assert_equal 1, @order.order_payment_notifications.where(outcome: "duplicate").count
  end

  test "an invalid mac leaves the order untouched" do
    params = notification_params(esito: "OK")
    params[:mac] = "0" * 40

    post nexi_notify_path, params: params

    assert_response :ok
    assert @order.reload.pending_payment?
  end

  test "#return never writes order state, only redirects" do
    get nexi_return_path(codTrans: @order.order_number, esito: "OK")

    assert_redirected_to order_path(@order)
    assert @order.reload.pending_payment?
  end

  private

  def notification_params(esito:)
    base = {
      codTrans: @order.order_number, esito: esito, importo: "3500", divisa: "EUR",
      data: "20260913", orario: "120000", codAut: "MP7EL4"
    }
    string_to_sign = "codTrans=#{base[:codTrans]}esito=#{base[:esito]}importo=#{base[:importo]}" \
                      "divisa=#{base[:divisa]}data=#{base[:data]}orario=#{base[:orario]}codAut=#{base[:codAut]}#{@mac_key}"
    base.merge(mac: Digest::SHA1.hexdigest(string_to_sign))
  end
end
