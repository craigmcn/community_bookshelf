ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    include ActiveJob::TestHelper
    include ActionMailer::TestHelper

    parallelize(workers: :number_of_processors)
    fixtures :all
  end
end

class ActionDispatch::IntegrationTest
  def sign_in_as(user)
    token = SecureRandom.hex(20)
    user.update_columns(remember_token: token)
    cookies[Clearance.configuration.cookie_name] = token
  end

  def auth_headers(user, scopes: ApiToken::SCOPES)
    {"Authorization" => "Bearer #{api_token_for(user, scopes: scopes).plaintext_token}"}
  end

  def api_token_for(user, scopes: ApiToken::SCOPES)
    ApiToken.generate!(user: user, name: "test token", scopes: scopes)
  end
end
