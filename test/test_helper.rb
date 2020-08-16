ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/autorun"
require "webmock/minitest"

Dir[Rails.root.join("test/support/**/*.rb")].sort.each { |f| require f }

module ActiveSupport
  class TestCase
    extend MiniTest::Spec::DSL
    include FactoryBot::Syntax::Methods

    before do
      WebMock.disable_net_connect!(
        allow_localhost: true,
        allow: Webdrivers::Common.subclasses.map(&:base_url)
      )

      StripeServer.setup
    end
  end
end
