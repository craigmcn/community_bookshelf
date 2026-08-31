# Be sure to restart your server when you modify this file.

# style-src allows 'unsafe-inline' for two independent reasons: the Font
# Awesome Kit script (loaded in app/views/layouts/application.html.erb)
# rewrites <i> tags into inline SVGs with inline style attributes at
# runtime, and the app's own views already use plenty of inline
# style="..." attributes directly (book covers, avatars, mailers, etc.) —
# self-hosting Font Awesome alone would not let this drop unsafe-inline.
# Every other directive stays nonce-free and inline-free.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src :self, :data, "https://ka-p.fontawesome.com"
    policy.img_src :self, :data, "https://covers.openlibrary.org"
    policy.object_src :none
    policy.script_src :self, "https://kit.fontawesome.com"
    policy.style_src :self, :unsafe_inline
    policy.connect_src :self, "https://ka-p.fontawesome.com"
    policy.base_uri :self
    policy.form_action :self
  end

  config.content_security_policy_report_only = false
end
