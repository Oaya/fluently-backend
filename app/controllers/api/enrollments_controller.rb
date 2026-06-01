class  Api::EnrollmentsController < ApplicationController
  before_action :authenticate_api_user!
    before_action :require_admin!, only: [ :course ]

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

  # GET /api/courses/:id/enrollments
  def course
    enrollments = Current.tenant.enrollments.includes(:user).where(course_id: params[:id])

    render json: enrollments.map { |e|
      e.as_json(only: [ :course_id, :status ]).merge(
        user: e.user.as_json(only: [ :id, :first_name, :last_name ]).merge(
          avatar: e.user.avatar.attached? ? rails_blob_url(e.user.avatar, host: request.base_url) : nil
        )
      )
    }
  end
end
