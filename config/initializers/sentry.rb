# Be sure to restart your server when you modify this file.

# No-op until SENTRY_DSN is set — lets every environment ship with the gem
# wired up without requiring a Sentry account to boot the app locally or in CI.
if ENV["SENTRY_DSN"].present?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
    config.environment = ENV.fetch("SENTRY_ENVIRONMENT", Rails.env)

    # Adjust this value in production to reduce overhead, or set a sampler
    # function for finer control.
    config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", "0.1").to_f
  end
end
