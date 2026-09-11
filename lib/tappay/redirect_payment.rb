# frozen_string_literal: true

module Tappay
  # Payment methods where TapPay answers with a payment_url and the customer
  # finishes paying on the provider's own page: LINE Pay, JKO Pay, iPass Money.
  # A status of 0 here means the URL was created, not that anyone has paid.
  class RedirectPayment < PrimePayment
    protected

    def payment_data
      super.merge(
        result_url: {
          frontend_redirect_url: options[:frontend_redirect_url],
          backend_notify_url: options[:backend_notify_url]
        }
      )
    end

    private

    def additional_required_options
      super + [:frontend_redirect_url, :backend_notify_url]
    end

    def validate_options!
      super
      validate_redirect_urls!
    end

    def validate_redirect_urls!
      validate_result_url_hash!(options[:result_url]) if options.key?(:result_url)

      return unless options[:frontend_redirect_url].to_s.strip.empty? ||
                    options[:backend_notify_url].to_s.strip.empty?

      raise ValidationError, "result_url must contain both frontend_redirect_url and backend_notify_url"
    end
  end
end
