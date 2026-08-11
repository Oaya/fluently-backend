require "test_helper"

class Api::HomeworksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create_admin
    @student = create_student(admin: @admin)
    @other_admin = create_admin
    @other_student = create_student(admin: @other_admin)
    @homework = create_homework(admin: @admin, student: @student)
  end

  test "index returns the admin's own students' homeworks" do
    other_homework = create_homework(admin: @other_admin, student: @other_student)

    get api_homeworks_url, headers: auth_header(@admin)
    assert_response :success

    ids = response.parsed_body.map { |h| h["id"] }
    assert_includes ids, @homework.id
    assert_not_includes ids, other_homework.id
  end

  test "index returns only the student's own homeworks" do
    get api_homeworks_url, headers: auth_header(@student)
    assert_response :success

    ids = response.parsed_body.map { |h| h["id"] }
    assert_equal [ @homework.id ], ids
  end

  test "show allows the owning admin" do
    get api_homework_url(@homework), headers: auth_header(@admin)
    assert_response :success
  end

  test "show allows the owning student" do
    get api_homework_url(@homework), headers: auth_header(@student)
    assert_response :success
  end

  test "show is not found for a different admin" do
    get api_homework_url(@homework), headers: auth_header(@other_admin)
    assert_response :not_found
  end

  test "create is forbidden for students" do
    post api_homeworks_url, params: { homework: { student_id: @student.id, title: "HW", due_date: 1.week.from_now.to_date, ai_generated: false } }, headers: auth_header(@student)
    assert_response :forbidden
  end

  test "create is blocked when the admin's subscription is not active" do
    @admin.update!(subscription_status: "past_due")

    post api_homeworks_url, params: { homework: { student_id: @student.id, title: "HW", due_date: 1.week.from_now.to_date, ai_generated: false } }, headers: auth_header(@admin)
    assert_response :payment_required
  end

  test "create builds a homework for the admin's own student" do
    assert_difference "Homework.count", 1 do
      post api_homeworks_url, params: { homework: { student_id: @student.id, title: "HW", due_date: 1.week.from_now.to_date, ai_generated: false } }, headers: auth_header(@admin)
    end
    assert_response :created
  end

  test "create rejects a student that does not belong to the admin" do
    post api_homeworks_url, params: { homework: { student_id: @other_student.id, title: "HW", due_date: 1.week.from_now.to_date, ai_generated: false } }, headers: auth_header(@admin)
    assert_response :not_found
  end

  test "create returns validation errors" do
    post api_homeworks_url, params: { homework: { student_id: @student.id, title: "", due_date: nil, ai_generated: false } }, headers: auth_header(@admin)
    assert_response :unprocessable_entity
  end

  test "update is forbidden for students" do
    patch api_homework_url(@homework), params: { homework: { title: "Updated" } }, headers: auth_header(@student)
    assert_response :forbidden
  end

  test "update modifies the homework" do
    patch api_homework_url(@homework), params: { homework: { title: "Updated" } }, headers: auth_header(@admin)
    assert_response :success
    assert_equal "Updated", @homework.reload.title
  end

  test "destroy is forbidden for students" do
    delete api_homework_url(@homework), headers: auth_header(@student)
    assert_response :forbidden
  end

  test "destroy removes a homework that already has a submission" do
    create_homework_submission(homework: @homework, student: @student)

    assert_difference "Homework.count", -1 do
      delete api_homework_url(@homework), headers: auth_header(@admin)
    end
    assert_response :no_content
  end
end
