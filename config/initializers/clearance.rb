Clearance.configure do |config|
  config.mailer_sender = "reply@example.com"
  config.rotate_csrf_on_sign_in = true
  # Match the session cookie (session_store.rb): Secure wherever SSL is enforced, and an explicit
  # Lax rather than the browser default, per #219's same-site deployment decision (#249).
  config.secure_cookie = Rails.application.config.force_ssl
  config.same_site = :lax
end
