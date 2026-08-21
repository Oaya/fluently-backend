module Api
  module Auth
    class PasswordsController < Devise::PasswordsController
      respond_to :json

      # POST /api/auth/password
      # Sends a password reset email
      def create
        email = params[:email].to_s.downcase.strip

        unless email.present?
          return render json: { error: "Email is required" }, status: :unprocessable_entity
        end

        user = User.find_by(email: email)

        # Always respond with success to prevent email enumeration
        if user
          raw_token, hashed_token = Devise.token_generator.generate(User, :reset_password_token)
          user.reset_password_token   = hashed_token
          user.reset_password_sent_at = Time.now.utc
          user.save(validate: false)

          UserMailer.reset_password_instructions(user, raw_token).deliver_later
        end

        render json: { message: "If that email is registered, a reset link has been sent." }, status: :ok
      end

      # PUT /api/auth/password
      # Resets the password using the token from the email link
      def update
        token                = params[:reset_password_token].to_s
        password             = params[:password].to_s
        password_confirmation = params[:password_confirmation].to_s

        if token.blank? || password.blank?
          return render json: { error: "Token and password are required" }, status: :unprocessable_entity
        end

        user = User.with_reset_password_token(token)

        unless user
          return render json: { error: "Reset link is invalid or has expired." }, status: :unprocessable_entity
        end

        if user.reset_password_period_valid?
          if user.reset_password(password, password_confirmation)
            render json: { message: "Password updated successfully" }, status: :ok
          else
            render json: { error: user.errors.full_messages.first }, status: :unprocessable_entity
          end
        else
          render json: { error: "Reset link has expired. Please request a new one." }, status: :unprocessable_entity
        end
      end
    end
  end
end
