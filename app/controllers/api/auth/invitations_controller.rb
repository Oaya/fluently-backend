module Api
  module Auth
    class InvitationsController < Devise::InvitationsController
      respond_to :json

      before_action :authenticate_api_user!, :require_admin!, :set_current_user, only: [ :create ]

      # POST /api/auth/invitation Send invitation email
      def create
        # TODO: We need to add guard to send invitaion with plan.
        result = invite_params.map do |inv_params|
          InviteUser.new(invited_by: current_api_user, params: inv_params).call
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
        params.require(:users).map do |inv_params|
          inv_params.permit(:email, :first_name, :last_name, :level)
        end
      end

      def accept_resource_params
        params.permit(:invitation_token, :password, :password_confirmation)
      end
    end
  end
end
