# app/controllers/api/lesson_recordings_controller.rb
class Api::LessonRecordingsController < ApplicationController
  before_action :authenticate_api_user!
  before_action :set_lesson

  def show
    recording = @lesson.lesson_recording
    return render json: { recording: nil } unless recording

    render json: {
      id:                  recording.id,
      duration_in_seconds: recording.duration_in_seconds,
      file_size:           recording.file_size,
      created_at:          recording.created_at,
      url:                 recording.video.attached? ? rails_blob_url(recording.video, host: request.base_url) : nil
    }
  end

  def create
    recording = @lesson.build_lesson_recording(
      duration_in_seconds: params[:duration_in_seconds],
      file_size:           params[:file_size]
    )
    recording.video.attach(params[:video_signed_id])

    if recording.save
      render json: { id: recording.id }, status: :created
    else
      render_error(recording.errors.full_messages, status: :unprocessable_entity)
    end
  end

  private

  def set_lesson
    @lesson = Lesson.find(params[:lesson_id])
  end
end
