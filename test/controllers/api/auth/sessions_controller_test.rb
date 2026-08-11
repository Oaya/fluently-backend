require "test_helper"

class Api::Auth::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "requires email and password" do
    post api_user_session_url, params: { email: "", password: "" }
    assert_response :unprocessable_entity
  end

  test "rejects an invalid password" do
    user = create_user(email: "login-#{SecureRandom.hex(4)}@example.com")

    post api_user_session_url, params: { email: user.email, password: "wrongpassword" }
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "Invalid email or password"
  end

  test "rejects an unconfirmed user" do
    user = create_user(email: "login-#{SecureRandom.hex(4)}@example.com", confirmed_at: nil)

    post api_user_session_url, params: { email: user.email, password: "password123" }
    assert_response :unauthorized
    assert_includes response.parsed_body["error"], "Confirm your email"
  end

  test "signs in with valid credentials" do
    user = create_user(email: "login-#{SecureRandom.hex(4)}@example.com")

    post api_user_session_url, params: { email: user.email, password: "password123" }
    assert_response :success

    body = response.parsed_body
    assert body["token"].present?
    assert_equal user.id, body["user"]["id"]
  end
end
