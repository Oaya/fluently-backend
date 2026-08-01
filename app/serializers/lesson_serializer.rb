class LessonSerializer
  include Rails.application.routes.url_helpers

  def initialize(lesson, host:)
    @lesson = lesson
    @host = host
  end

  def lesson_result
    {
      id: @lesson.id,
      scheduled_at: @lesson.scheduled_at,
      duration_in_minutes: @lesson.duration_in_minutes,
      status: @lesson.status,
      topic: @lesson.topic,
      note: @lesson.note,
      language: @lesson.language,
      payment_status: @lesson.payment_status,
      created_at: @lesson.created_at,
      updated_at: @lesson.updated_at,
      room_name: @lesson.room_name,
      meeting_duration_in_seconds: @lesson.meeting_duration_in_seconds,
      meeting_feedback: @lesson.meeting_feedback,
      recording_url: recording_url,
      student: {
        id: @lesson.student.id,
        first_name: @lesson.student.first_name,
        last_name: @lesson.student.last_name,
        avatar: UserSerializer.new(@lesson.student, host: @host).avatar_url,
        email: @lesson.student.email,
        learning_languages: @lesson.student.learning_languages
      }
    }
  end

  private

  def recording_url
    return nil unless @lesson.lesson_recording&.video&.attached?
    rails_blob_url(@lesson.lesson_recording.video, host: @host)
  end
end
