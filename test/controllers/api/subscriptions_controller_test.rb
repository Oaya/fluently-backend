require "test_helper"

class Api::SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create_admin
    @student = create_student(admin: @admin)
    @plan = create_plan(name: "Pro")
  end

  test "payment_checkout is forbidden for students" do
    post payment_checkout_api_subscription_url, params: { plan: @plan.name }, headers: auth_header(@student)
    assert_response :forbidden
  end

  test "payment_checkout returns the checkout payload" do
    fake_service = Object.new
    def fake_service.checkout_session(plan, user)
      { client_secret: "secret_123" }
    end

    stub_method(Subscriptions, :new, fake_service) do
      post payment_checkout_api_subscription_url, params: { plan: @plan.name }, headers: auth_header(@admin)
    end

    assert_response :success
    assert_equal "secret_123", response.parsed_body["client_secret"]
  end

  test "cancel is forbidden for students" do
    post cancel_api_subscription_url, headers: auth_header(@student)
    assert_response :forbidden
  end

  test "cancel returns the cancellation payload" do
    fake_service = Object.new
    def fake_service.cancel_subscription(user)
      { message: "Subscription will be cancelled at the end of the current billing period" }
    end

    stub_method(Subscriptions, :new, fake_service) do
      post cancel_api_subscription_url, headers: auth_header(@admin)
    end

    assert_response :success
    assert_equal "Subscription will be cancelled at the end of the current billing period", response.parsed_body["message"]
  end

  test "change_plan rejects an unknown plan name" do
    post change_plan_api_subscription_url, params: { plan: "nonexistent" }, headers: auth_header(@admin)
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "Invalid plan"
  end

  test "change_plan returns the change_plan payload for a known plan" do
    fake_service = Object.new
    def fake_service.change_plan(user, new_plan)
      { message: "Plan changed successfully" }
    end

    stub_method(Subscriptions, :new, fake_service) do
      post change_plan_api_subscription_url, params: { plan: @plan.name }, headers: auth_header(@admin)
    end

    assert_response :success
    assert_equal "Plan changed successfully", response.parsed_body["message"]
  end
end
