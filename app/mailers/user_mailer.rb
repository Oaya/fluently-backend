class UserMailer < ApplicationMailer
  # Sends a password reset link to the user.
  # Called from Api::Auth::PasswordsController#create.
  def reset_password_instructions(user, token)
    @user = user
    @reset_url = "#{frontend_url}/reset-password?reset_password_token=#{token}"

    mail(
      to: user.email,
      subject: "Reset your Fluently password"
    )
  end

  private

  def frontend_url
    Rails.application.credentials.frontend_url ||
      ENV.fetch("FRONTEND_URL", "http://localhost:5173")
  end
end
