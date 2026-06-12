class ApplicationController < ActionController::API
  before_action :set_current_user, unless: :devise_controller?

  private

  def render_error(message, status:)
    msg = message.is_a?(Array) ? message.join(", ") : message.to_s
    render json: { error: msg }, status: status
  end

  def set_current_user
    return unless current_api_user

    Current.user = current_api_user
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
end
