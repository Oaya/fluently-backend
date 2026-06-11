class Api::StripeWebhooksController < ApplicationController
  def receive
    endpoint_secret = ENV["STRIPE_WEBHOOK_SECRET"]
    return render_error("Missing Stripe webhook secret", status: :internal_server_error) if endpoint_secret.blank?

    payload = request.raw_post
    signature = request.headers["Stripe-Signature"]

    event = Stripe::Webhook.construct_event(payload, signature, endpoint_secret)

    case event.type
    when "checkout.session.completed"
      handle_checkout_session_completed(event.data.object)
    when "invoice.paid"
      handle_invoice_paid(event.data.object)
    when "invoice.payment_failed"
      handle_invoice_payment_failed(event.data.object)
    else
      Rails.logger.info("Unhandled event type: #{event.type}")
    end

    head :ok
  rescue Stripe::SignatureVerificationError => e
    render_error("Invalid signature: #{e.message}", status: :bad_request)
  rescue JSON::ParserError => e
    render_error("Invalid payload: #{e.message}", status: :bad_request)
  rescue => e
    Rails.logger.error("Error processing webhook: #{e.full_message}")
    render_error("Internal server error", status: :internal_server_error)
  end

  private

  def handle_checkout_session_completed(session)
    customer_id = session.customer
    subscription_id = session.subscription
    user_data = session.metadata
    user_id = user_data["user_id"]

    unless user_id.present?
      Rails.logger.error("Missing user ID in session metadata: #{user_data}")
      return
    end

    user = User.find_by(id: user_id)
    if user
      user.update!(stripe_customer_id: customer_id, stripe_subscription_id: subscription_id)
    end
  rescue => e
    Rails.logger.error("Error handling checkout session completed: #{e.full_message}")
  end

  def handle_invoice_paid(invoice)
    Rails.logger.info("Invoice paid: #{invoice.id}")
    user = User.find_by(stripe_subscription_id: invoice.subscription)

    if user
      user.update!(
        subscription_status: "active",
        current_period_end: Time.at(invoice.lines.data[0].period.end),
        cancel_at_period_end: false,
        plan: Plan.find_by(stripe_price_id: invoice.lines.data[0].price.id)
      )
    else
      Rails.logger.error("User not found for subscription ID: #{invoice.subscription}")
    end
  rescue => e
    Rails.logger.error("Error handling invoice paid: #{e.full_message}")
  end

  def handle_invoice_payment_failed(invoice)
    Rails.logger.info("Invoice payment failed: #{invoice.id}")
    user = User.find_by(stripe_subscription_id: invoice.subscription)

    if user
      user.update!(
        subscription_status: "past_due",
        current_period_end: Time.at(invoice.lines.data[0].period.end),
        cancel_at_period_end: false,
        plan: Plan.find_by(stripe_price_id: invoice.lines.data[0].price.id)
      )
    else
      Rails.logger.error("User not found for subscription ID: #{invoice.subscription}")
    end
  rescue => e
    Rails.logger.error("Error handling invoice payment failed: #{e.full_message}")
  end
end
