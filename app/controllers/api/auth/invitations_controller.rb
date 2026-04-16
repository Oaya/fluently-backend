module Api
  module Auth
    class InvitationsController < Devise::InvitationsController
      respond_to :json

      before_action :authenticate_api_user!, :require_admin!, :set_current_user_tenant_plan, only: [ :create ]

      # POST /api/auth/invitation Send invitation email
      def create
        result = invite_params.map do | inv_params|
          InviteUser.new(tenant: Current.tenant, invited_by: current_api_user, params: inv_params).call
        end

        failed = result.select { |r| r.errors.any? }

        if failed.any?
          render_error(failed.map { |r| r.errors.full_messages }.flatten, status: :unprocessable_entity)
        else
          render json: { message: "Invitations Email sent successfully" }, status: :ok
        end
      rescue StandardError => e
        render_error(e.message, status: :forbidden)
      end


      # PATCH /api/auth/invitation -> Accept invitation and create password
      def update
        self.resource = accept_resource
        Rails.logger.warn("resource_name=#{resource_name}")
        Rails.logger.warn("ACCEPT_PARAMS=#{params.to_unsafe_h.inspect}")
        Rails.logger.warn("RESOURCE_ERRORS=#{resource.errors.full_messages.inspect}")

        if resource.errors.empty?
          resource.update!(status: "active")
          payload = SignInWithJwt.new(self).issue_jwt(resource, message: "Created your new password")
          render json: payload, status: :ok
        else
          render_error(resource.errors.full_messages, status: :unprocessable_entity)
        end
      rescue => e
        render_error(e.message, status: :internal_server_error)
      end


      private

      def invite_params
        allowed_roles = %w[student instructor admin]
        params.require(:users).map do |inv_params|
          permitted = inv_params.permit(:email, :first_name, :last_name, courses: [:id, :title])

          role = inv_params[:role].to_s.downcase
          pp role
          role = "student" unless allowed_roles.include?(role)

          permitted.merge(role: role)
        end
      end

      def accept_resource_params
        params.permit(:invitation_token, :password, :password_confirmation)
      end
    end
  end
end
