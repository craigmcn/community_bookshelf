require "test_helper"

class SecurityHeadersTest < ActionDispatch::IntegrationTest
  test "CSP allows the Font Awesome kit's actual asset host" do
    get books_url
    assert_response :success

    csp = @response.headers["Content-Security-Policy"]
    assert csp.present?
    # The b41e4928e6 kit (app/views/layouts/application.html.erb) is a Pro
    # kit — it fetches its CSS/webfonts from ka-p.fontawesome.com, not the
    # free-kit host ka-f.fontawesome.com. Every icon on the page silently
    # failed to render until this matched the kit's real host (see the
    # commit that added this test for a live-browser repro).
    assert_includes csp, "ka-p.fontawesome.com"
    assert_not_includes csp, "ka-f.fontawesome.com"
  end
end
