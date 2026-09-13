require "test_helper"

module Nexi
  class GatewayTest < ActiveSupport::TestCase
    setup do
      @gateway = Nexi::Gateway.new
      @mac_key = Rails.application.credentials.dig(:nexi, :sandbox, :mac_key)
    end

    test "build_payment_params converts the amount to cents" do
      order = orders(:pending_order) # total_amount: 35.00

      params = @gateway.build_payment_params(
        order, return_url: "https://example.com/return",
        cancel_url: "https://example.com/return", notify_url: "https://example.com/notify"
      )

      assert_equal "3500", params["importo"]
    end

    test "verify_mac accepts a correctly computed mac" do
      response_params = {
        "codTrans" => "ABC123", "esito" => "OK", "importo" => "4000",
        "divisa" => "EUR", "data" => "20260912", "orario" => "120000", "codAut" => "000111"
      }
      string_to_sign = "codTrans=ABC123esito=OKimporto=4000divisa=EURdata=20260912orario=120000codAut=000111#{@mac_key}"
      response_params["mac"] = Digest::SHA1.hexdigest(string_to_sign)

      assert @gateway.verify_mac(response_params)
    end

    test "verify_mac rejects a tampered mac" do
      response_params = {
        "codTrans" => "ABC123", "esito" => "OK", "importo" => "4000",
        "divisa" => "EUR", "data" => "20260912", "orario" => "120000", "codAut" => "000111",
        "mac" => "0" * 40
      }

      assert_not @gateway.verify_mac(response_params)
    end

    test "verify_mac rejects a message with no mac at all" do
      assert_not @gateway.verify_mac({ "codTrans" => "ABC123", "esito" => "OK" })
    end
  end
end
