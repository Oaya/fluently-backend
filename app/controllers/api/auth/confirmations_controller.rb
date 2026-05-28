module Api
  module Auth
    class ConfirmationsController < Devise::ConfirmationsController
      respond_to :json

      def show
        self.resource = resource_class.confirm_by_token(params[:confirmation_token])

        frontend_url = ENV.fetch("FRONTEND_URL", "http://localhost:5174")

        if resource.errors.empty?
          resource.update!(status: "active")
          redirect_to "#{frontend_url}/confirm-email?status=success", allow_other_host: true
        else
          redirect_to "#{frontend_url}/confirm-email?status=error", allow_other_host: true
        end
      end
    end
  end
end
