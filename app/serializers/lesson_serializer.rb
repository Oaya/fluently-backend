class LessonSerializer
  include Rails.application.routes.url_helpers

  def initialize(lesson, host:, current_user: nil)
    @lesson = lesson
    @host = host
    @current_user = current_user
  end

  def lesson_result
    {
      id: @lesson.id,
      scheduled_at: @lesson.scheduled_at,
      duration_in_minutes: @lesson.duration_in_minutes,
      status: @lesson.status,
      topic: @lesson.topic,
      teacher_note: @lesson.teacher_note,
      language: @lesson.language,
      invoice_status: @lesson.invoice&.status,
      cancellation_fee_amount: @lesson.cancellation_fee_amount,
      created_at: @lesson.created_at,
      updated_at: @lesson.updated_at,
      room_name: @lesson.room_name,
      meeting_duration_in_seconds: @lesson.meeting_duration_in_seconds,
      meeting_feedback: @lesson.meeting_feedback,
      meeting_note: @lesson.meeting_note,
      note_shared: @lesson.note_shared,
      recording_url: recording_url,
      student_note: @current_user&.role == "student" ? @lesson.student_note : nil,
      invoice_id: @lesson.invoice&.id,
      student: {
        id: @lesson.student.id,
        first_name: @lesson.student.first_name,
        last_name: @lesson.student.last_name,
        avatar: UserSerializer.new(@lesson.student, host: @host).avatar_url,
        email: @lesson.student.email,
        language_levels: @lesson.student.language_levels,
        lesson_rate: @lesson.student.lesson_rate
      },
      admin: {
        first_name: @lesson.admin.first_name,
        last_name: @lesson.admin.last_name,
        email: @lesson.admin.email,
        no_show_fee_percent: @lesson.admin.no_show_fee_percent,
        late_cancellation_fee_percent: @lesson.admin.late_cancellation_fee_percent,
        cancellation_window_hours: @lesson.admin.cancellation_window_hours,
        currency: @lesson.admin.currency
      }
    }
  end

  private

  def recording_url
    return nil unless @lesson.lesson_recording&.video&.attached?
    rails_blob_url(@lesson.lesson_recording.video, host: @host)
  end
end
