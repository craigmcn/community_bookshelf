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
end
