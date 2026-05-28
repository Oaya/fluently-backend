class Subscriptions
  def checkout_session(plan, user)
    Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
    unless plan
      return render_error("Invalid plan: #{params[:plan]}", :unprocessable_entity)
    end
    # Create or reuse a Stripe customer by email
    customer = Stripe::Customer.list(email: user.email).data.first
    customer ||= Stripe::Customer.create(
      email: user.email,
      name: "#{user.first_name} #{user.last_name}",
      metadata: { tenant_id: user.tenant.id }
    )
    frontend = Rails.application.credentials[:frontend_url] || "http://localhost:5174"

    # Put signup info into metadata so you can create the user after payment is successful in the webhook
    begin
      session = Stripe::Checkout::Session.create(
        ui_mode: "embedded",
        mode: "subscription",
        customer: customer.id,
        line_items: [ { price: plan.stripe_price_id, quantity: 1 } ],
        return_url: "#{frontend}/admin/dashboard",
        metadata: {
          "email" => user.email,
          "first_name" => user.first_name,
          "last_name" => user.last_name,
          "tenant_id" => user.tenant.id,
          "plan_name" => plan.name,
          "plan_id" => plan.id
        }
      )
    rescue Stripe::StripeError => e
      return render_error(e.message, :bad_request)
    end
    { client_secret: session.client_secret }
  end


  def cancel_subscription(tenant)
    # if the current plan is free, just the update the tenant status to "canceled"
    if tenant.plan.name == "basic"
      tenant.update(status: "canceled", current_period_end: nil, cancel_at_period_end: nil)
      { message: "Subscription cancelled successfully" }
    else
      # For paid plan, cancel the subscription in Stripe and update the tenant cancel_at_period_end to true
      if tenant.stripe_subscription_id.present?
        Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
        begin
          Stripe::Subscription.update(
            tenant.stripe_subscription_id,
            {
              cancel_at_period_end: true
            }
          )
          tenant.update(cancel_at_period_end: true)
          { message: "Subscription will be cancelled at the end of the current billing period" }
        rescue Stripe::StripeError => e
          render_error(e.message, :bad_request)
        end
      end
    end
  end

  def change_plan(tenant, new_plan)
    unless new_plan
      return render_error("Invalid plan: #{params[:plan]}", :unprocessable_entity)
    end

    Stripe.api_key = ENV["STRIPE_SECRET_KEY"]

    # if the new plan is free, just update the tenant's plan and status, and cancel the subscription in Stripe if exists
    if new_plan.name == "basic"
      begin
        Stripe::Subscription.update(
          tenant.stripe_subscription_id,
          {
            cancel_at_period_end: true
          }
        )
      rescue Stripe::StripeError => e
        return render_error(e.message, :bad_request)
      end
      tenant.update(plan: new_plan, cancel_at_period_end: false, status: "active")
      pp tenant
      { message: "Plan changed successfully" }
    else
      # if there in no existing subscription, need to create a new subscription in Strip, and let frontend to handle the payment flow by redirecting to the checkout page

      if tenant.stripe_subscription_id.blank?
        return { redirect_to_checkout: true }
      end

      begin
        subscription = Stripe::Subscription.retrieve(tenant.stripe_subscription_id)
        item = subscription.items.data.first

        return render_error("Subscription has no items", :unprocessable_entity) unless item
        updated_sub = Stripe::Subscription.update(
          tenant.stripe_subscription_id,
          {
            cancel_at_period_end: false,
            items: [ {
              id: item.id,
              price: new_plan.stripe_price_id
             } ]
           }
        )
        tenant.update!(
          plan: new_plan,
          current_period_end: Time.at(updated_sub.items.data[0].current_period_end),
          status: "active",
          cancel_at_period_end: false
         )
        { message: "Plan changed successfully" }
      rescue Stripe::StripeError => e
        render_error(e.message, :bad_request)
      end
    end
  end
end
