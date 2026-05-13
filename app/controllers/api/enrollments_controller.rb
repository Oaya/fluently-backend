class  Api::EnrollmentsController < ApplicationController
  before_action :authenticate_api_user!

  def start
    enrollment = Enrollment.find_by(id: params[:id], user: current_api_user)
    unless enrollment
      return render_error("Enrollment not found", status: :not_found)
    end
    SeedEnrollmentLessonProgressJob.perform_later(enrollment.id)
    enrollment.update(status: :in_progress)
  end

  def complete_lesson
    enrollment = Enrollment.find_by(id: params[:id], user: current_api_user)
    unless enrollment
      return render_error("Enrollment not found", status: :not_found)
    end

    lesson_progress = LessonProgress.find_by(enrollment: enrollment, lesson_id: params[:lesson_id])
    unless lesson_progress
      return render_error("Lesson progress not found", status: :not_found)
    end

    lesson_progress.update!(status: :completed, progress: 100)
    render json: { message: "Lesson completed" }, status: :ok
  end
end
