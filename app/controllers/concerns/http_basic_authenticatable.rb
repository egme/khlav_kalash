module HttpBasicAuthenticatable
  extend ActiveSupport::Concern

  def http_authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == "admin" && password == "password"
    end
  end
end
