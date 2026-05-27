module Api
  module Auth
    class RegistrationsController < Devise::RegistrationsController
      respond_to :json

      # POST api/auth/registrations#create
      def create
        email = sign_up_params[:email].to_s.downcase

        # Check if the user exists or not
        exists_user = User.find_by(email: email)

        if exists_user
          # if user is already confrimed then send error message that it can't use the email
          if exists_user.confirmed?
            render_error("Cannot register email #{email}", status: :unprocessable_entity)
            return
          else
            exists_user.send_confirmation_instructions
            render json: { message: "Confirmation instruction sent to #{email}" }, status: :ok
            return
          end
        end

        # If the user doesn't exists, signup with Tenant and plan
        # find plan first
        plan = Plan.find_by(name: tenant_params[:plan])

        unless plan
          render_error("Invalid Plan", status: :unprocessable_entity)
          return
        end


        # create tenant, user and membership save user and send confirmation
        user = nil
        ActiveRecord::Base.transaction do
          tenant_status = plan.name == "basic" ? "active" : "pending"
          tenant = Tenant.create!(name: tenant_params[:tenant], plan: plan, status: tenant_status)

          user = User.new(sign_up_params.merge(email: email, tenant: tenant, status: "invited"))
          user.skip_confirmation_notification!
          user.save!

          tenant.update!(billing_owner_id: user.id)

          Membership.create!(user: user, tenant: tenant, role: "admin")
        end

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
        params.permit(
          :email,
          :password,
          :password_confirmation,
          :first_name,
          :last_name
        )
      end

      def tenant_params
        params.permit(
          :tenant,
          :plan
        )
      end
    end
  end
end
