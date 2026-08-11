require "test_helper"

class Api::Auth::ConfirmationsControllerTest < ActionDispatch::IntegrationTest
  test "confirms a user with a valid token and redirects to the frontend success page" do
    user = create_user(email: "confirm-#{SecureRandom.hex(4)}@example.com", confirmed_at: nil, status: "invited")
    raw_token, enc_token = Devise.token_generator.generate(User, :confirmation_token)
    user.update_columns(confirmation_token: enc_token, confirmation_sent_at: Time.current)

    get api_user_confirmation_url(confirmation_token: raw_token)

    assert_response :redirect
    assert_includes response.headers["Location"], "confirm-email?status=success"

    user.reload
    assert user.confirmed?
    assert_equal "active", user.status
  end

  test "redirects to the frontend error page for an invalid token" do
    get api_user_confirmation_url(confirmation_token: "not-a-real-token")

    assert_response :redirect
    assert_includes response.headers["Location"], "confirm-email?status=error"
  end
end
