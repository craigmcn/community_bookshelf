require "test_helper"

class ApiTokensControllerTest < ActionDispatch::IntegrationTest
  test "guest is redirected to sign in" do
    get api_tokens_url
    assert_redirected_to sign_in_path
  end

  test "member can view their own tokens" do
    api_token_for(users(:member))
    sign_in_as users(:member)

    get api_tokens_url

    assert_response :success
  end

  test "member's token list doesn't include another member's tokens" do
    own_token = api_token_for(users(:member), scopes: ["read:books"])
    other_token = api_token_for(users(:moderator), scopes: ["read:books"])
    sign_in_as users(:member)

    get api_tokens_url

    assert_includes response.body, own_token.token_prefix
    assert_not_includes response.body, other_token.token_prefix
  end

  test "member can create a scoped token and sees the plaintext once" do
    sign_in_as users(:member)

    assert_difference "ApiToken.count", 1 do
      post api_tokens_url, params: {api_token: {name: "my script", scopes: ["read:books"], expires_in: "30"}}
    end

    assert_redirected_to api_tokens_url
    follow_redirect!
    assert_response :success

    token = users(:member).api_tokens.last
    assert_equal "my script", token.name
    assert_equal ["read:books"], token.scopes
    assert token.expires_at.present?
  end

  test "create with no scopes selected re-renders the form with an error" do
    sign_in_as users(:member)

    assert_no_difference "ApiToken.count" do
      post api_tokens_url, params: {api_token: {name: "my script", scopes: [], expires_in: "never"}}
    end

    assert_response :unprocessable_content
  end

  test "member can revoke their own token" do
    token = api_token_for(users(:member))
    sign_in_as users(:member)

    assert_difference "ApiToken.count", -1 do
      delete api_token_url(token)
    end

    assert_redirected_to api_tokens_url
  end

  test "member cannot revoke another member's token" do
    token = api_token_for(users(:moderator))
    sign_in_as users(:member)

    assert_no_difference "ApiToken.count" do
      delete api_token_url(token)
    end

    assert_response :not_found
  end
end
