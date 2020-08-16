require "test_helper"
require "webdrivers/chromedriver"

# https://github.com/bblimke/webmock/blob/master/lib/webmock/request_pattern.rb#L186
# Since WebMock disabled the `only_with_scheme` flag since 3.6.0, when doing system tests,
# it ends up splitting the webdriver URL `http://127.0.0.1:9543` into a schema-less and
# schema-full version, and Addressable::URI.parse on the schemaless version throws
#
# WebMock has been flip flopping between implementations on this, since this patch causes
# problems unrelated to this one (which we're not affected by).
# https://github.com/bblimke/webmock/pull/758 (what fixed our issue)
# https://github.com/bblimke/webmock/pull/829 (what caused our issue again)
#
# The below patch implements WebMock 3.6.0 behaviour. Remove it when unnecessary.
module WebMock
  class URIAddressablePattern
    def matches_with_variations?(uri)
      normalized_template = Addressable::Template.new(WebMock::Util::URI.heuristic_parse(@pattern.pattern))

      WebMock::Util::URI.variations_of_uri_as_strings(uri, only_with_scheme: true).any? do |u|
        normalized_template.match(u)
      end
    end
  end
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  before do
    WebMock.disable!
    Capybara.default_max_wait_time = 5
  end

  # See https://gorails.com/blog/fill-in-stripe-elements-js-for-sca-3d-secure-2-and-capybara on below:

  # Fills out the Stripe card element with the provided card details in Capybara
  # You can also provide a custom selector to find the correct iframe
  # By default, we use the ID of "#card-element" which Stripe uses in their documentation
  def fill_stripe_elements(card:, expiry: "1234", cvc: "123", postal: "12345", selector: "#card-element > div > iframe")
    find_frame(selector) do
      card.to_s.chars.each do |piece|
        find_field("cardnumber").send_keys(piece)
      end

      find_field("exp-date").send_keys expiry
      find_field("cvc").send_keys cvc
      find_field("postal").send_keys postal
    end
  end

  # Completes SCA authentication successfully
  def complete_stripe_sca
    find_frame("body > div > iframe") do
      # This helps find the inner iframe in the SCA modal's challenge frame which doesn't load immediately
      sleep 1

      find_frame("#challengeFrame") do
        find_frame(".FullscreenFrame") do
          click_on "Complete authentication"
        end
      end
    end
  end

  # Fails SCA authentication
  def fail_stripe_sca
    find_frame("body > div > iframe") do
      # This helps find the inner iframe in the SCA modal's challenge frame which doesn't load immediately
      sleep 1

      find_frame("#challengeFrame") do
        find_frame(".FullscreenFrame") do
          click_on "Fail authentication"
        end
      end
    end
  end

  # Generic helper for finding an iframe
  def find_frame(selector)
    using_wait_time(15) do
      frame = find(selector)
      within_frame(frame) do
        yield
      end
    end
  end
end
