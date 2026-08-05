class UserSerializer
  include Rails.application.routes.url_helpers

  def initialize(user, host:)
    @user = user
    @host = host
  end

  def user_result
    json = {
      id: @user.id,
      email: @user.email,
      first_name: @user.first_name,
      last_name: @user.last_name,
      role: @user.role,
      avatar: avatar_url,
      status: @user.status,
      timezone: @user.timezone,
      created_at: @user.created_at
    }

    if @user.role === "student"
      json[:learning_languages] = @user.learning_languages
    end

    unless @user.role == "student"
      json[:subscription] = {
        status: @user.subscription_status,
        plan: @user.plan&.name,
        price: @user.plan&.price,
        current_period_end: @user.current_period_end,
        cancel_at_period_end: @user.cancel_at_period_end,
        has_stripe_subscription: @user.stripe_subscription_id.present? || @user.stripe_customer_id.present?
      }
    end

    json
  end

  def user_with_statues_result
    {
      id: @user.id,
      email: @user.email,
      first_name: @user.first_name,
      last_name: @user.last_name,
      role: @user.role,
      created_at: @user.created_at,
      status: User.statuses[@user.status],
      avatar: avatar_url,
      hw_status: homework_status_badge(@user.homeworks)
    }
  end

  def avatar_url
    return nil unless @user.avatar.attached?
    rails_blob_url(@user.avatar, host: @host)
  end

  private

  def homework_status_badge(homeworks)
    return nil if homeworks.empty?

    statuses = homeworks.map { |hw| HomeworkSerializer.new(hw, nil, host: @host).send(:homework_status_badge, hw) }
    return "overdue" if statuses.include?("overdue")
    return "done" if statuses.all? { |s| %w[submitted reviewed].include?(s) }

    "pending"
  end
end
