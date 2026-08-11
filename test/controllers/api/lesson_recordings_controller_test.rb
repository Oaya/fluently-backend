require "test_helper"

class Api::LessonRecordingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create_admin
    @student = create_student(admin: @admin)
    @other_admin = create_admin
    @lesson = create_lesson(admin: @admin, student: @student)
  end

  test "show returns nil when there is no recording" do
    get api_lesson_recording_url(@lesson), headers: auth_header(@admin)
    assert_response :success
    assert_nil response.parsed_body["recording"]
  end

  test "show returns the recording when it exists" do
    @lesson.create_lesson_recording!(duration_in_seconds: 120, file_size: 1024)

    get api_lesson_recording_url(@lesson), headers: auth_header(@student)
    assert_response :success
    assert_equal 120, response.parsed_body["duration_in_seconds"]
  end

  test "show is not found for a lesson the user cannot access" do
    get api_lesson_recording_url(@lesson), headers: auth_header(@other_admin)
    assert_response :not_found
  end

  test "create attaches a video and creates the recording" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("fake video data"),
      filename: "test.mp4",
      content_type: "video/mp4"
    )

    assert_difference "LessonRecording.count", 1 do
      post api_lesson_recording_url(@lesson), params: { video_signed_id: blob.signed_id, duration_in_seconds: 90, file_size: 2048 }, headers: auth_header(@admin)
    end
    assert_response :created

    recording = @lesson.reload.lesson_recording
    assert recording.video.attached?
  end

  test "create is not found for a lesson the user cannot access" do
    post api_lesson_recording_url(@lesson), params: { duration_in_seconds: 90 }, headers: auth_header(@other_admin)
    assert_response :not_found
  end
end
