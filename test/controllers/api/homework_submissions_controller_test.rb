require "test_helper"

class Api::HomeworkSubmissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create_admin
    @student = create_student(admin: @admin)
    @other_admin = create_admin
    @other_student = create_student(admin: @other_admin)
    @homework = create_homework(admin: @admin, student: @student)
    @submission = create_homework_submission(homework: @homework, student: @student)
  end

  test "index returns submissions for the admin's own students" do
    other_homework = create_homework(admin: @other_admin, student: @other_student)
    other_submission = create_homework_submission(homework: other_homework, student: @other_student)

    get api_homework_submissions_url, headers: auth_header(@admin)
    assert_response :success

    ids = response.parsed_body.map { |s| s["id"] }
    assert_includes ids, @submission.id
    assert_not_includes ids, other_submission.id
  end

  test "index returns only the student's own submissions" do
    get api_homework_submissions_url, headers: auth_header(@student)
    assert_response :success

    ids = response.parsed_body.map { |s| s["id"] }
    assert_equal [ @submission.id ], ids
  end

  test "show is not found for an unrelated admin" do
    get api_homework_submission_url(@submission), headers: auth_header(@other_admin)
    assert_response :not_found
  end

  test "create is forbidden for admins" do
    post api_homework_submissions_url, params: { homework_submission: { homework_id: @homework.id, answer_text: "answer" } }, headers: auth_header(@admin)
    assert_response :forbidden
  end

  test "create rejects a homework that is not the student's own" do
    other_homework = create_homework(admin: @other_admin, student: @other_student)

    post api_homework_submissions_url, params: { homework_submission: { homework_id: other_homework.id, answer_text: "answer" } }, headers: auth_header(@student)
    assert_response :not_found
  end

  test "create finds or initializes the student's submission for the homework" do
    new_homework = create_homework(admin: @admin, student: @student)

    post api_homework_submissions_url, params: { homework_submission: { homework_id: new_homework.id, answer_text: "my answer", status: "submitted" } }, headers: auth_header(@student)
    assert_response :created

    submission = HomeworkSubmission.find_by(homework: new_homework, student: @student)
    assert_equal "my answer", submission.answer_text
    assert_equal "submitted", submission.status
    assert_not_nil submission.submitted_at
  end

  test "create accepts link attachments" do
    new_homework = create_homework(admin: @admin, student: @student)

    post api_homework_submissions_url, params: {
      homework_submission: { homework_id: new_homework.id, answer_text: "answer", status: "draft" },
      attachments: [ { type: "link", url: "https://example.com/doc" } ]
    }, headers: auth_header(@student)

    assert_response :created
    submission = HomeworkSubmission.find_by(homework: new_homework, student: @student)
    assert_equal 1, submission.submission_attachments.count
    assert_equal "https://example.com/doc", submission.submission_attachments.first.url
  end

  test "create is blocked for an already reviewed submission" do
    @submission.update!(status: "reviewed", reviewed_at: Time.current)

    post api_homework_submissions_url, params: { homework_submission: { homework_id: @homework.id, answer_text: "changed" } }, headers: auth_header(@student)
    assert_response :unprocessable_entity
  end

  test "feedback is forbidden for students" do
    patch feedback_api_homework_submission_url(@submission), params: { homework_submission: { score: "good", feedback: "nice" } }, headers: auth_header(@student)
    assert_response :forbidden
  end

  test "feedback is blocked when the admin's subscription is not active" do
    @admin.update!(subscription_status: "past_due")

    patch feedback_api_homework_submission_url(@submission), params: { homework_submission: { score: "good", feedback: "nice" } }, headers: auth_header(@admin)
    assert_response :payment_required
  end

  test "feedback reviews the submission" do
    patch feedback_api_homework_submission_url(@submission), params: { homework_submission: { score: "good", feedback: "nice work", notes: "internal" } }, headers: auth_header(@admin)
    assert_response :created

    @submission.reload
    assert_equal "reviewed", @submission.status
    assert_equal "good", @submission.score
    assert_equal "nice work", @submission.feedback
    assert_not_nil @submission.reviewed_at
  end

  test "destroy is forbidden for a non-owning student" do
    delete api_homework_submission_url(@submission), headers: auth_header(@other_student)
    assert_response :not_found
  end

  test "destroy is blocked for a non-draft submission" do
    @submission.update!(status: "submitted", submitted_at: Time.current)

    delete api_homework_submission_url(@submission), headers: auth_header(@student)
    assert_response :unprocessable_entity
  end

  test "destroy removes a draft submission owned by the student" do
    assert_difference "HomeworkSubmission.count", -1 do
      delete api_homework_submission_url(@submission), headers: auth_header(@student)
    end
    assert_response :no_content
  end
end
