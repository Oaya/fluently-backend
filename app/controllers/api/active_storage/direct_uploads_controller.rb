module Api
  module ActiveStorage
    class DirectUploadsController < ApplicationController
      before_action :authenticate_api_user!

      def create
        type_prefix = params[:kind].to_s

        base_key = ::ActiveStorage::Blob.generate_unique_secure_token
        custom_key = "users/#{Current.user.id}/#{type_prefix}/#{base_key}"

        blob = ::ActiveStorage::Blob.create_before_direct_upload!(
          filename: params[:filename],
          byte_size: params[:byte_size],
          checksum: params[:checksum],
          content_type: params[:content_type],
          key: custom_key
        )

        render json: {
          signed_id: blob.signed_id,
          direct_upload: {
            url: blob.service_url_for_direct_upload,
            headers: blob.service_headers_for_direct_upload
          }
        }

      rescue => e
        Rails.logger.error(e.full_message)
        render_error("#{e.class}: #{e.message}", status: :internal_server_error)
      end
    end
  end
end
