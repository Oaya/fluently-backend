class Api::LessonProgressesController < ApplicationController
  before_action :authenticate_api_user!
  before_action :set_lesson_progress

  def complete
    LessonProgressService.new(@lesson_progress).complete
    render_response
  end

  def incomplete
    LessonProgressService.new(@lesson_progress).incomplete
    render_response
  end

  def save_position
    LessonProgressService.new(@lesson_progress).save_position(
      position_params[:watched_seconds].to_i,
      position_params[:duration_seconds].to_i
    )
    render_response
  end

  private

  def set_lesson_progress
    @lesson_progress = LessonProgress
      .joins(:enrollment)
      .where(enrollments: { tenant_id: Current.tenant.id, user_id: current_api_user.id })
      .find(params[:id])
  end

  def position_params
    params.require(:lesson_progress).permit(:watched_seconds, :duration_seconds)
  end

  def render_response
    enrollment = @lesson_progress.enrollment
    render json: {
      lesson_progress: { id: @lesson_progress.id, status: @lesson_progress.status, progress: @lesson_progress.progress, watched_seconds: @lesson_progress.watched_seconds },
      enrollment: { id: enrollment.id, status: enrollment.status, overall_progress: enrollment.overall_progress }
    }
  end
end
