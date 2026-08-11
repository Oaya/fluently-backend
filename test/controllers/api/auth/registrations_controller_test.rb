require "test_helper"

class Api::Auth::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @free_plan = create_plan(name: "free", price: 0)
    @pro_plan = create_plan(name: "pro", price: 2000)
  end

  test "rejects an unknown plan" do
    post api_user_registration_url, params: {
      email: "signup-#{SecureRandom.hex(4)}@example.com", password: "password123", password_confirmation: "password123",
      first_name: "Aya", last_name: "Okizaki", plan: "nonexistent"
    }

    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "Invalid Plan"
  end

  test "registers a new admin on the free plan with an active subscription" do
    email = "signup-#{SecureRandom.hex(4)}@example.com"

    assert_difference "User.count", 1 do
      post api_user_registration_url, params: {
        email: email, password: "password123", password_confirmation: "password123",
        first_name: "Aya", last_name: "Okizaki", plan: "free"
      }
    end

    assert_response :created
    user = User.find_by(email: email)
    assert_equal "admin", user.role
    assert_equal "invited", user.status
    assert_equal "active", user.subscription_status
    assert_equal @free_plan.id, user.plan_id
  end

  test "registers a new admin on a paid plan with a pending subscription" do
    email = "signup-#{SecureRandom.hex(4)}@example.com"

    post api_user_registration_url, params: {
      email: email, password: "password123", password_confirmation: "password123",
      first_name: "Aya", last_name: "Okizaki", plan: "pro"
    }

    assert_response :created
    user = User.find_by(email: email)
    assert_equal "pending", user.subscription_status
  end

  test "rejects registering an email that is already confirmed" do
    existing = create_user(email: "signup-#{SecureRandom.hex(4)}@example.com")

    post api_user_registration_url, params: {
      email: existing.email, password: "password123", password_confirmation: "password123",
      first_name: "Aya", last_name: "Okizaki", plan: "free"
    }

    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "Cannot register email"
  end

  test "resends confirmation instructions for an unconfirmed existing email" do
    existing = create_user(email: "signup-#{SecureRandom.hex(4)}@example.com", confirmed_at: nil)

    assert_no_difference "User.count" do
      post api_user_registration_url, params: {
        email: existing.email, password: "password123", password_confirmation: "password123",
        first_name: "Aya", last_name: "Okizaki", plan: "free"
      }
    end

    assert_response :success
    assert_includes response.parsed_body["message"], "Confirmation instruction sent"
  end
end
