class Subscriptions
  def checkout_session(plan, user)
    Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
    unless plan
      return { error: "Invalid plan" }
    end

    customer = Stripe::Customer.list(email: user.email).data.first
    customer ||= Stripe::Customer.create(
      email: user.email,
      name: "#{user.first_name} #{user.last_name}",
      metadata: { user_id: user.id }
    )

    frontend = Rails.application.credentials[:frontend_url] || "http://localhost:5174"

    session = Stripe::Checkout::Session.create(
      ui_mode: "embedded",
      mode: "payment",
      customer: customer.id,
      line_items: [ { price: plan.stripe_price_id, quantity: 1 } ],
      return_url: "#{frontend}/admin/dashboard",
      metadata: {
        "email" => user.email,
        "first_name" => user.first_name,
        "last_name" => user.last_name,
        "user_id" => user.id,
        "plan_name" => plan.name,
        "plan_id" => plan.id
      }
    )

    { client_secret: session.client_secret }
  rescue Stripe::StripeError => e
    { error: e.message }
  end

  def cancel_subscription(user)
    if user.plan&.name == "free"
      user.update(subscription_status: "canceled", current_period_end: nil, cancel_at_period_end: nil)
      { message: "Subscription cancelled successfully" }
    elsif user.stripe_subscription_id.present?
      Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
      Stripe::Subscription.update(user.stripe_subscription_id, { cancel_at_period_end: true })
      user.update(cancel_at_period_end: true)
      { message: "Subscription will be cancelled at the end of the current billing period" }
    end
  rescue Stripe::StripeError => e
    { error: e.message }
  end

  def change_plan(user, new_plan)
    Stripe.api_key = ENV["STRIPE_SECRET_KEY"]

    if new_plan.name == "free"
      if user.stripe_subscription_id.present?
        Stripe::Subscription.update(user.stripe_subscription_id, { cancel_at_period_end: true })
      end
      user.update(plan: new_plan, cancel_at_period_end: false, subscription_status: "active")
      { message: "Plan changed successfully" }
    else
      return { redirect_to_checkout: true } if user.stripe_subscription_id.blank?

      subscription = Stripe::Subscription.retrieve(user.stripe_subscription_id)
      item = subscription.items.data.first

      return { error: "Subscription has no items" } unless item

      updated_sub = Stripe::Subscription.update(
        user.stripe_subscription_id,
        {
          cancel_at_period_end: false,
          items: [ { id: item.id, price: new_plan.stripe_price_id } ]
        }
      )
      user.update!(
        plan: new_plan,
        current_period_end: Time.at(updated_sub.items.data[0].current_period_end),
        subscription_status: "active",
        cancel_at_period_end: false
      )
      { message: "Plan changed successfully" }
    end
  rescue Stripe::StripeError => e
    { error: e.message }
  end
end
