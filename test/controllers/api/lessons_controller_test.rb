require "test_helper"

class Api::LessonsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create_admin
    @student = create_student(admin: @admin)
    @other_admin = create_admin
    @other_student = create_student(admin: @other_admin)
    @lesson = create_lesson(admin: @admin, student: @student)
  end

  test "index returns the admin's own students' lessons" do
    other_lesson = create_lesson(admin: @other_admin, student: @other_student)

    get api_lessons_url, headers: auth_header(@admin)
    assert_response :success

    ids = response.parsed_body.map { |l| l["id"] }
    assert_includes ids, @lesson.id
    assert_not_includes ids, other_lesson.id
  end

  test "index returns only the student's own lessons" do
    get api_lessons_url, headers: auth_header(@student)
    assert_response :success

    ids = response.parsed_body.map { |l| l["id"] }
    assert_equal [ @lesson.id ], ids
  end

  test "show is not found for a different admin" do
    get api_lesson_url(@lesson), headers: auth_header(@other_admin)
    assert_response :not_found
  end

  test "create is forbidden for students" do
    post api_lessons_url, params: { lesson: { student_id: @student.id, scheduled_at: 1.day.from_now } }, headers: auth_header(@student)
    assert_response :forbidden
  end

  test "create is blocked when the admin's subscription is not active" do
    @admin.update!(subscription_status: "past_due")

    post api_lessons_url, params: { lesson: { student_id: @student.id, scheduled_at: 1.day.from_now } }, headers: auth_header(@admin)
    assert_response :payment_required
  end

  test "create builds a lesson for the admin's own student" do
    @admin.update!(currency: "USD", timezone: "UTC")
    @student.update!(lesson_rate: 25, timezone: "UTC")

    assert_difference "Lesson.count", 1 do
      post api_lessons_url, params: { lesson: { student_id: @student.id, scheduled_at: 1.day.from_now } }, headers: auth_header(@admin)
    end
    assert_response :created
  end

  test "create rejects a student that does not belong to the admin" do
    post api_lessons_url, params: { lesson: { student_id: @other_student.id, scheduled_at: 1.day.from_now } }, headers: auth_header(@admin)
    assert_response :not_found
  end

  test "update is forbidden for students" do
    patch api_lesson_url(@lesson), params: { lesson: { topic: "Grammar" } }, headers: auth_header(@student)
    assert_response :forbidden
  end

  test "update modifies the lesson" do
    patch api_lesson_url(@lesson), params: { lesson: { topic: "Grammar" } }, headers: auth_header(@admin)
    assert_response :success
    assert_equal "Grammar", @lesson.reload.topic
  end

  test "destroy is forbidden for students" do
    delete api_lesson_url(@lesson), headers: auth_header(@student)
    assert_response :forbidden
  end

  test "destroy removes a lesson that has a recording" do
    @lesson.create_lesson_recording!(duration_in_seconds: 60)

    assert_difference "Lesson.count", -1 do
      delete api_lesson_url(@lesson), headers: auth_header(@admin)
    end
    assert_response :no_content
  end

  test "today returns lessons scheduled today for the current user" do
    todays_lesson = create_lesson(admin: @admin, student: @student, scheduled_at: Time.current.middle_of_day)
    create_lesson(admin: @admin, student: @student, scheduled_at: 1.week.from_now)

    get today_api_lessons_url, headers: auth_header(@admin)
    assert_response :success

    ids = response.parsed_body.map { |l| l["id"] }
    assert_includes ids, todays_lesson.id
    assert_equal 1, ids.size
  end

  test "token returns a livekit token for a user with access to the lesson" do
    stub_method(LivekitTokenService, :generate, "fake.jwt.token") do
      get token_api_lesson_url(@lesson), headers: auth_header(@student)
    end

    assert_response :success
    body = response.parsed_body
    assert_equal "fake.jwt.token", body["token"]
    assert_equal @lesson.room_name, body["room_name"]
  end

  test "token is not found for a lesson the user cannot access" do
    get token_api_lesson_url(@lesson), headers: auth_header(@other_admin)
    assert_response :not_found
  end

  test "end is forbidden for students" do
    patch end_api_lesson_url(@lesson), params: { lesson: { status: "completed" } }, headers: auth_header(@student)
    assert_response :forbidden
  end

  test "end is blocked when the admin's subscription is not active" do
    @admin.update!(subscription_status: "past_due")

    patch end_api_lesson_url(@lesson), params: { lesson: { status: "completed" } }, headers: auth_header(@admin)
    assert_response :payment_required
  end

  test "end updates meeting fields for the admin" do
    patch end_api_lesson_url(@lesson), params: { lesson: { status: "completed", meeting_duration_in_seconds: 600, meeting_feedback: "went well" } }, headers: auth_header(@admin)
    assert_response :success

    @lesson.reload
    assert_equal "completed", @lesson.status
    assert_equal 600, @lesson.meeting_duration_in_seconds
  end

  test "student_note is forbidden for admins" do
    patch student_note_api_lesson_url(@lesson), params: { lesson: { student_note: "note" } }, headers: auth_header(@admin)
    assert_response :forbidden
  end

  test "student_note updates the note for the owning student" do
    patch student_note_api_lesson_url(@lesson), params: { lesson: { student_note: "my note" } }, headers: auth_header(@student)
    assert_response :success
    assert_equal "my note", @lesson.reload.student_note
  end

  test "student_note is forbidden for a student that does not own the lesson" do
    patch student_note_api_lesson_url(@lesson), params: { lesson: { student_note: "note" } }, headers: auth_header(@other_student)
    assert_response :not_found
  end

  test "meeting_note is forbidden for students" do
    patch meeting_note_api_lesson_url(@lesson), params: { lesson: { meeting_note: "note" } }, headers: auth_header(@student)
    assert_response :forbidden
  end

  test "meeting_note updates the note for the owning admin" do
    patch meeting_note_api_lesson_url(@lesson), params: { lesson: { meeting_note: "internal note" } }, headers: auth_header(@admin)
    assert_response :success
    assert_equal "internal note", @lesson.reload.meeting_note
  end
end
