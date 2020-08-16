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
      StripeServer.setup
    end
  end
end
