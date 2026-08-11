require "test_helper"
require "ostruct"

class Api::StripeWebhooksControllerTest < ActionDispatch::IntegrationTest
  def post_webhook(event)
    original_secret = ENV["STRIPE_WEBHOOK_SECRET"]
    ENV["STRIPE_WEBHOOK_SECRET"] = "whsec_test_secret"

    stub_method(Stripe::Webhook, :construct_event, event) do
      post api_stripe_webhook_url,
        params: "{}",
        headers: { "CONTENT_TYPE" => "application/json", "Stripe-Signature" => "test_sig" }
    end
  ensure
    ENV["STRIPE_WEBHOOK_SECRET"] = original_secret
  end

  test "returns internal_server_error when the webhook secret is not configured" do
    original_secret = ENV["STRIPE_WEBHOOK_SECRET"]
    ENV["STRIPE_WEBHOOK_SECRET"] = nil

    post api_stripe_webhook_url, params: "{}", headers: { "CONTENT_TYPE" => "application/json" }
    assert_response :internal_server_error
  ensure
    ENV["STRIPE_WEBHOOK_SECRET"] = original_secret
  end

  test "returns bad_request when the signature is invalid" do
    original_secret = ENV["STRIPE_WEBHOOK_SECRET"]
    ENV["STRIPE_WEBHOOK_SECRET"] = "whsec_test_secret"

    error = ->(*) { raise Stripe::SignatureVerificationError.new("bad signature", "sig") }
    stub_method(Stripe::Webhook, :construct_event, error) do
      post api_stripe_webhook_url,
        params: "{}",
        headers: { "CONTENT_TYPE" => "application/json", "Stripe-Signature" => "bad_sig" }
    end

    assert_response :bad_request
  ensure
    ENV["STRIPE_WEBHOOK_SECRET"] = original_secret
  end

  test "checkout.session.completed stores the stripe customer and subscription ids" do
    admin = create_admin(stripe_customer_id: nil, stripe_subscription_id: nil)

    session = OpenStruct.new(customer: "cus_123", subscription: "sub_123", metadata: { "user_id" => admin.id })
    event = OpenStruct.new(type: "checkout.session.completed", data: OpenStruct.new(object: session))

    post_webhook(event)

    assert_response :success
    admin.reload
    assert_equal "cus_123", admin.stripe_customer_id
    assert_equal "sub_123", admin.stripe_subscription_id
  end

  test "invoice.paid marks the subscription active" do
    plan = create_plan(stripe_price_id: "price_123")
    admin = create_admin(stripe_subscription_id: "sub_123", subscription_status: "pending")

    period_end = 1.month.from_now.to_i
    line = OpenStruct.new(period: OpenStruct.new(end: period_end), price: OpenStruct.new(id: "price_123"))
    invoice = OpenStruct.new(id: "in_123", subscription: "sub_123", lines: OpenStruct.new(data: [ line ]))
    event = OpenStruct.new(type: "invoice.paid", data: OpenStruct.new(object: invoice))

    post_webhook(event)

    assert_response :success
    admin.reload
    assert_equal "active", admin.subscription_status
    assert_equal plan.id, admin.plan_id
    assert_not admin.cancel_at_period_end
  end

  test "invoice.payment_failed marks the subscription past_due" do
    plan = create_plan(stripe_price_id: "price_456")
    admin = create_admin(stripe_subscription_id: "sub_456", subscription_status: "active")

    period_end = 1.month.from_now.to_i
    line = OpenStruct.new(period: OpenStruct.new(end: period_end), price: OpenStruct.new(id: "price_456"))
    invoice = OpenStruct.new(id: "in_456", subscription: "sub_456", lines: OpenStruct.new(data: [ line ]))
    event = OpenStruct.new(type: "invoice.payment_failed", data: OpenStruct.new(object: invoice))

    post_webhook(event)

    assert_response :success
    admin.reload
    assert_equal "past_due", admin.subscription_status
    assert_equal plan.id, admin.plan_id
  end
end
