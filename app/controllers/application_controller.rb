class ApplicationController < ActionController::API
  private

  def render_error(message, status:)
    msg = message.is_a?(Array) ? message.join(", ") : message.to_s
    render json: { error: msg }, status: status
  end

  def require_admin!
    user = current_api_user
    return render_error("Unauthorized", status: :unauthorized) unless user
    return if user.role == "admin"

    render_error("No permission to access", status: :forbidden)
  end

  def require_active_subscription!
    user = current_api_user
    status = user.subscription_status.to_s
    return if status.blank? || status == "active"

    render_error(
      "Subscription is #{status}. Please update payment information to reactivate subscription.",
      status: :payment_required
    )
  end

  def require_pro_plan!
    user = current_api_user
    return if user.plan&.name == "pro" && user.subscription_status == "active"

    render_error(
      "This feature requires an active Pro plan subscription.",
      status: :payment_required
    )
  end
end
