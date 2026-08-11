require "test_helper"

class Api::ActiveStorage::DirectUploadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user
    @checksum = Digest::MD5.base64digest("file contents")
  end

  test "requires authentication" do
    post api_rails_active_storage_direct_uploads_url, params: {
      filename: "avatar.png", byte_size: 13, checksum: @checksum, content_type: "image/png", kind: "avatars"
    }
    assert_response :unauthorized
  end

  test "creates a blob and returns direct upload instructions" do
    post api_rails_active_storage_direct_uploads_url, params: {
      filename: "avatar.png", byte_size: 13, checksum: @checksum, content_type: "image/png", kind: "avatars"
    }, headers: auth_header(@user)

    assert_response :success
    body = response.parsed_body

    assert body["signed_id"].present?
    assert body["direct_upload"]["url"].present?

    blob = ActiveStorage::Blob.find_signed(body["signed_id"])
    assert_equal "avatar.png", blob.filename.to_s
    assert_includes blob.key, "users/#{@user.id}/avatars/"
  end
end
