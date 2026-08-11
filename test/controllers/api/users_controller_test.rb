require "test_helper"

class Api::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create_admin
    @other_admin = create_admin
    @student = create_student(admin: @admin, first_name: "Aya", last_name: "Okizaki")
    @other_students_student = create_student(admin: @other_admin)
  end

  test "requires authentication" do
    get api_users_url
    assert_response :unauthorized
  end

  test "index requires admin role" do
    get api_users_url, headers: auth_header(@student)
    assert_response :forbidden
  end

  test "index returns only the admin's own students, excluding the admin itself" do
    get api_users_url, headers: auth_header(@admin)
    assert_response :success

    ids = response.parsed_body.map { |u| u["id"] }
    assert_includes ids, @student.id
    assert_not_includes ids, @admin.id
    assert_not_includes ids, @other_students_student.id
  end

  test "index filters by search" do
    get api_users_url, params: { search: "Okizaki" }, headers: auth_header(@admin)
    assert_response :success

    ids = response.parsed_body.map { |u| u["id"] }
    assert_equal [ @student.id ], ids
  end

  test "with_statues requires admin role" do
    get with_statues_api_users_url, headers: auth_header(@student)
    assert_response :forbidden
  end

  test "with_statues returns the admin's own students" do
    get with_statues_api_users_url, headers: auth_header(@admin)
    assert_response :success

    ids = response.parsed_body.map { |u| u["id"] }
    assert_equal [ @student.id ], ids
  end

  test "show allows an admin to view themselves" do
    get api_user_url(@admin), headers: auth_header(@admin)
    assert_response :success
    assert_equal @admin.id, response.parsed_body["id"]
  end

  test "show allows an admin to view their own student" do
    get api_user_url(@student), headers: auth_header(@admin)
    assert_response :success
    assert_equal @student.id, response.parsed_body["id"]
  end

  test "show forbids an admin from viewing another admin's student" do
    get api_user_url(@other_students_student), headers: auth_header(@admin)
    assert_response :not_found
  end

  test "show allows a student to view themselves" do
    get api_user_url(@student), headers: auth_header(@student)
    assert_response :success
    assert_equal @student.id, response.parsed_body["id"]
  end

  test "show forbids a student from viewing another user" do
    get api_user_url(@admin), headers: auth_header(@student)
    assert_response :not_found
  end

  test "update updates the user's attributes" do
    patch api_user_url(@student), params: { user: { first_name: "Updated" } }, headers: auth_header(@admin)
    assert_response :success
    assert_equal "Updated", @student.reload.first_name
  end

  test "update returns validation errors" do
    patch api_user_url(@student), params: { user: { first_name: "" } }, headers: auth_header(@admin)
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["error"], "can't be blank"
  end

  test "destroy is forbidden for students" do
    delete api_user_url(@student), headers: auth_header(@student)
    assert_response :forbidden
  end

  test "destroy is blocked when the admin's subscription is not active" do
    @admin.update!(subscription_status: "past_due")

    delete api_user_url(@student), headers: auth_header(@admin)
    assert_response :payment_required
  end

  test "destroy removes the admin's own student" do
    assert_difference "User.count", -1 do
      delete api_user_url(@student), headers: auth_header(@admin)
    end
    assert_response :no_content
  end
end
