# Be sure to restart your server when you modify this file.

# The app doesn't use any of these browser features itself; disabling them
# outright closes off a class of abuse if a page is ever framed or an XSS
# slips through.
Rails.application.config.permissions_policy do |policy|
  policy.camera :none
  policy.microphone :none
  policy.geolocation :none
  policy.usb :none
  policy.payment :none
  policy.fullscreen :self
end
