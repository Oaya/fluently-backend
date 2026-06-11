module Api
  module Auth
    class RegistrationsController < Devise::RegistrationsController
      respond_to :json

      # POST api/auth/registrations#create
      def create
        email = sign_up_params[:email].to_s.downcase

        exists_user = User.find_by(email: email)

        if exists_user
          if exists_user.confirmed?
            render_error("Cannot register email #{email}", status: :unprocessable_entity)
            return
          else
            exists_user.send_confirmation_instructions
            render json: { message: "Confirmation instruction sent to #{email}" }, status: :ok
            return
          end
        end

        plan = Plan.find_by(name: plan_params[:plan])

        unless plan
          render_error("Invalid Plan", status: :unprocessable_entity)
          return
        end

        subscription_status = plan.name == "free" ? "active" : "pending"

        user = User.new(
          sign_up_params.merge(
            email: email,
            role: "admin",
            plan: plan,
            subscription_status: subscription_status,
            status: "invited"
          )
        )
        user.skip_confirmation_notification!
        user.save!

        begin
          user.send_confirmation_instructions
        rescue StandardError => e
          Rails.logger.error("Failed to send confirmation email to #{email}: #{e.message}")
        end

        render json: { message: "Confirmation instruction sent to #{email}" }, status: :created

      rescue ActiveRecord::RecordInvalid => e
        render_error(e.record.errors.full_messages, status: :unprocessable_entity)
      end

      private

      def sign_up_params
        params.permit(:email, :password, :password_confirmation, :first_name, :last_name)
      end

      def plan_params
        params.permit(:plan)
      end
    end
  end
end
