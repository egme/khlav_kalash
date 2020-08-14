module StripePayments
  class APIError < StandardError; end
  class Intent < Struct.new(:id, :client_secret, :status, :paid_at); end

  class << self
    def create_intent(amount, currency)
      build_intent(
        Stripe::PaymentIntent.create(
          amount: amount,
          currency: currency
        )
      )
    rescue StandardError => e
      raise_error(e)
    end

    def retrieve_intent(intent_id)
      build_intent(
        Stripe::PaymentIntent.retrieve(intent_id)
      )
    rescue StandardError => e
      raise_error(e)
    end

    private

    def build_intent(intent)
      created_ts = intent.as_json.dig("charges", "data", 0, "created")
      Intent.new(
        intent.id,
        intent.client_secret,
        intent.status,
        created_ts.nil? ? nil : Time.zone.at(created_ts)
      )
    end

    def raise_error(err)
      eid = SecureRandom.uuid
      Rails.logger.error "Stripe error #{eid}: #{err.class.name}: #{err.message}"
      # pp "Stripe error #{eid}: #{err.class.name}: #{err.message}" if Rails.env.test?
      raise APIError, eid
    end
  end
end
