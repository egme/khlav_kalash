module StripeServer
  INTENTS_URL = "https://api.stripe.com/v1/payment_intents".freeze

  class << self
    attr_reader :intents

    def intent_url_template
      Addressable::Template.new("#{INTENTS_URL}{/payment_intent_id}")
    end

    def create_intent(status = :requires_payment_method)
      raise NotImplementedError unless supported_statuses.include? status

      {
        id: SecureRandom.uuid,
        client_secret: SecureRandom.uuid,
        status: status.to_s,
        charges: {
          data: [
            {
              created: (status == :succeeded ? Time.current.to_i : nil)
            }
          ]
        }
      }.tap { |intent| @intents << intent }
    end

    def break
      @broken = true
    end

    def setup
      stub_intents_url
      stub_intent_url
      clear
    end

    private

    def clear
      @intents = []
      @broken = nil
    end

    def supported_statuses
      %i[
        requires_payment_method
        requires_confirmation
        requires_action
        processing
        requires_capture
        canceled
        succeeded
      ]
    end

    def headers
      { "Content-Type": "application/json" }
    end

    def stub_intents_url
      WebMock
        .stub_request(:post, INTENTS_URL)
        .to_return do
          next { status: 500 } if @broken

          {
            status: 200,
            headers: headers,
            body: create_intent.to_json
          }
        end
    end

    def stub_intent_url
      WebMock
        .stub_request(:get, intent_url_template)
        .to_return do |request|
          next { status: 500 } if @broken

          id = intent_url_template.extract(URI.parse(request.uri)).fetch("payment_intent_id")
          intent = @intents.find { |i| i[:id] == id }

          next { status: 404 } unless intent

          {
            status: 200,
            headers: headers,
            body: intent.to_json
          }
        end
    end
  end
end
