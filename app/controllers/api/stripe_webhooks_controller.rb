class Api::StripeWebhooksController < ApplicationController
  def receive
    endpoint_secret = ENV["STRIPE_WEBHOOK_SECRET"]
    return render_error("Missing Stripe webhook secret", :internal_server_error) if endpoint_secret.blank?

    payload = request.raw_post
    signature = request.headers["Stripe-Signature"]

    event = Stripe::Webhook.construct_event(payload, signature, endpoint_secret)

    pp event.type


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
    render_error("Invalid signature: #{e.message}", :bad_request)
  rescue JSON::ParserError => e
    render_error("Invalid payload: #{e.message}", :bad_request)
  rescue => e
    Rails.logger.error("Error processing webhook: #{e.full_message}")
    render_error("Internal server error", :internal_server_error)
  end

  private

  def handle_checkout_session_completed(session)
    # get the customer id and subscription id from the session
    customer_id = session.customer
    subscription_id = session.subscription

    user_data = session.metadata
    tenant_id = user_data["tenant_id"]

    unless tenant_id.present?
      Rails.logger.error("Missing tenant ID in session metadata: #{user_data}")
      return
    end

    # Update the tenant with the Stripe customer and subscription IDs
    tenant = Tenant.find_by(id: tenant_id)
    if tenant
      tenant.update!(stripe_customer_id: customer_id, stripe_subscription_id: subscription_id)
    end

  rescue => e
    Rails.logger.error("Error handling checkout session completed: #{e.full_message}")
  end


  def handle_invoice_paid(invoice)
    Rails.logger.info("Invoice paid: #{invoice.id}")
    # You can add logic here to update your database or send notifications
    tenant = Tenant.find_by(stripe_subscription_id: invoice.subscription)

    if tenant
      tenant.update!(status: "active", current_period_end: Time.at(invoice.lines.data[0].period.end), cancel_at_period_end: false, plan: Plan.find_by(stripe_price_id: invoice.lines.data[0].price.id))
    else
      Rails.logger.error("Tenant not found for subscription ID: #{invoice.subscription}")
    end
  rescue => e
    Rails.logger.error("Error handling invoice paid: #{e.full_message}")
  end

  def handle_invoice_payment_failed(invoice)
    Rails.logger.info("Invoice payment failed: #{invoice.id}")
    tenant = Tenant.find_by(stripe_subscription_id: invoice.subscription)

    if tenant
      tenant.update!(status: "past_due", current_period_end: Time.at(invoice.lines.data[0].period.end), cancel_at_period_end: false, plan: Plan.find_by(stripe_price_id: invoice.lines.data[0].price.id))
    else
      Rails.logger.error("Tenant not found for subscription ID: #{invoice.subscription}")
    end
  rescue => e
    Rails.logger.error("Error handling invoice payment failed: #{e.full_message}")
  end
end
