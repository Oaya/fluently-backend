module Api
  module Auth
    class UsersController < ApplicationController
      before_action :authenticate_api_user!
      include Rails.application.routes.url_helpers


      def me
        user = Current.user
        return render_error("Not authenticated", status: :unauthorized) unless user

        render json: UserSerializer.new(user, host: request.base_url).as_json
      end


      def update_me
        user = Current.user
        return render_error("Not authenticated", status: :unauthorized) unless user

        if user_params.key?(:avatar_signed_id)
          signed_id = user_params[:avatar_signed_id].to_s

          if signed_id.present?
            # Delete the previous attachment first
            user.avatar.purge_later if user.avatar.attached?

            user.avatar.attach(signed_id)

            # Ensure the attachment is persisted before responding
            user.reload
          else
            user.avatar.purge_later if user.avatar.attached?
          end
        end

        user.assign_attributes(user_params.except(:avatar_signed_id))
        user.save!

        render json: UserSerializer.new(user, host: request.base_url).as_json
      rescue => e
        Rails.logger.error(e.full_message)
        render_error("#{e.class}: #{e.message}", status: :internal_server_error)
      end

      def update_password
        user = Current.user
        return render_error("Not authenticated", status: :unauthorized) unless user
        current_password = params[:current_password]
        new_password = params[:new_password]

        unless user.valid_password?(current_password)
          return render_error("Current password is incorrect", status: :unprocessable_entity)
        end

        user.password = new_password
        if user.save
          render json: { message: "Password updated successfully" }
        else
          render_error(user.errors.full_messages, status: :unprocessable_entity)
        end
      rescue => e
        Rails.logger.error(e.full_message)
        render_error("#{e.class}: #{e.message}", status: :internal_server_error)
      end

      def signup_status
        user = Current.user
        if user
          render json: { signed_up: true, email: user.email }
        else
          render json: { signed_up: false }
        end
      end

      private

      def user_params
        params.permit(:first_name, :last_name, :avatar_signed_id, :email, :timezone, :learning_language)
      end
    end
  end
end
