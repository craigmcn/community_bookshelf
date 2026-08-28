# Be sure to restart your server when you modify this file.

# Explicit rather than relying on config.force_ssl alone to imply `secure` —
# spells out the intent regardless of how force_ssl is configured per environment.
Rails.application.config.session_store :cookie_store,
  key: "_community_bookshelf_session",
  secure: Rails.env.production?,
  same_site: :lax
