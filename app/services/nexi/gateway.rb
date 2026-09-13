module Nexi
  class Gateway
    class MissingCredentials < StandardError; end

    def initialize(env: Rails.env.production? ? :production : :sandbox)
      @credentials = Rails.application.credentials.dig(:nexi, env)
      raise MissingCredentials, "Missing Nexi credentials for environment #{env}" if @credentials.blank?
    end

    def payment_form_url
      @credentials[:pay_url]
    end

    def build_payment_params(order, return_url:, cancel_url:, notify_url:)
      cod_trans = order.order_number
      divisa = order.currency
      importo = amount_in_cents(order.total_amount)

      {
        "alias" => alias_code,
        "importo" => importo,
        "divisa" => divisa,
        "codTrans" => cod_trans,
        "url" => return_url,
        "url_back" => cancel_url,
        "urlpost" => notify_url,
        "mail" => order.guest_email,
        "nome" => order.guest_first_name,
        "cognome" => order.guest_last_name,
        "mac" => compute_request_mac(cod_trans: cod_trans, divisa: divisa, importo: importo)
      }.compact
    end

    def verify_mac(params)
      received = params["mac"] || params[:mac]
      return false if received.blank?

      ActiveSupport::SecurityUtils.secure_compare(compute_response_mac(params), received.to_s)
    end

    private

    def alias_code = @credentials[:alias]
    def mac_key = @credentials[:mac_key]
    def amount_in_cents(decimal_amount) = (decimal_amount * 100).round.to_s

    def compute_request_mac(cod_trans:, divisa:, importo:)
      Digest::SHA1.hexdigest("codTrans=#{cod_trans}divisa=#{divisa}importo=#{importo}#{mac_key}")
    end

    def compute_response_mac(params)
      value = ->(key) { (params[key] || params[key.to_sym]).to_s }
      string_to_sign =
        "codTrans=#{value.call('codTrans')}" \
        "esito=#{value.call('esito')}" \
        "importo=#{value.call('importo')}" \
        "divisa=#{value.call('divisa')}" \
        "data=#{value.call('data')}" \
        "orario=#{value.call('orario')}" \
        "codAut=#{value.call('codAut')}" \
        "#{mac_key}"
      Digest::SHA1.hexdigest(string_to_sign)
    end
  end
end
