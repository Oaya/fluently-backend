class UserSerializer
  include Rails.application.routes.url_helpers

  def initialize(user, host:)
    @user = user
    @host = host
  end

  def as_json
    {
      id: @user.id,
      email: @user.email,
      first_name: @user.first_name,
      last_name: @user.last_name,
      role: @user.role,
      avatar: avatar_url,
      status: @user.status,
      subscription: {
        status: @user.subscription_status,
        plan: @user.plan&.name,
        current_period_end: @user.current_period_end,
        cancel_at_period_end: @user.cancel_at_period_end,
        has_stripe_subscription: @user.stripe_subscription_id.present? || @user.stripe_customer_id.present?
      }
    }
  end

  private

  def avatar_url
    return nil unless @user.avatar.attached?
    rails_blob_url(@user.avatar, host: @host)
  end
end
