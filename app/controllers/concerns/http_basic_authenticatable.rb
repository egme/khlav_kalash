module HttpBasicAuthenticatable
  extend ActiveSupport::Concern

  def http_authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == ENV.fetch("ADMIN_USERNAME") && password == ENV.fetch("ADMIN_PASSWORD")
    end
  end
end
