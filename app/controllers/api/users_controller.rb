class Api::UsersController < ApplicationController
  before_action :authenticate_api_user!
  before_action :require_admin!, only: [ :index ]
  before_action :require_admin!, :require_active_subscription!, only: [ :bulk_delete ]
  include Rails.application.routes.url_helpers

  # GET /api/users
  # This endpoint get students
  def index
    users = User.includes(:admin).filtering(filter_params).where.not(id: current_api_user.id)
    users = users.order(sort_params) if sort_params.present?

    render json: users.map { |user| user_result(user) }
  end

  # GET /api/users/:id
  def show
    user = User.find(params[:id])
    render json: user_result(user)
  end

  # DELETE /api/users/bulk_delete
  def bulk_delete
    user_ids = user_delete_params[:user_ids] || []
    unless user_ids.is_a?(Array)
      return render_error("user_ids must be an array", status: :bad_request)
    end

    users = User.where(id: user_ids).where.not(id: current_api_user.id)
    ids = users.pluck(:id)

    enrollment_ids = Enrollment.where(user_id: ids).pluck(:id)
    LessonProgress.where(enrollment_id: enrollment_ids).delete_all
    Enrollment.where(id: enrollment_ids).delete_all
    deleted_count = users.delete_all

    render json: { deleted_count: deleted_count }, status: :ok
  end

  # GET /api/users/:id/courses
  def courses
    user = User.find(params[:id])

    courses_as_role = if user.role == "admin"
      Course.all
    else
      Course.joins(:enrollments).where(enrollments: { user_id: params[:id] })
    end

    render json: courses_as_role.map { |course|
      { id: course.id, title: course.title, published: course.published }
    }
  end

  def enrollments
    user = User.find(params[:id])
    enrollments = user.enrollments.includes(:course).order(created_at: :desc)

    render json: enrollments.map { |enrollment|
      {
        id: enrollment.id,
        status: enrollment.status,
        course: enrollment.course.as_json.merge(
          thumbnail: enrollment.course.thumbnail.attached? ? rails_blob_url(enrollment.course.thumbnail, host: request.base_url) : nil
        ),
        enrolled_at: enrollment.created_at
      }
    }
  end

  def course_status
    user = User.find(params[:id])
    course = Course.find(params[:course_id])
    enrollment = user.enrollments.find_by(course: course)

    unless enrollment
      return render_error("User is not enrolled in this course", status: :not_found)
    end

    total_lessons = Lesson.joins(section: :course).where(sections: { course_id: course.id }).count
    lesson_progresses = []
    progress_percentage = 0

    if enrollment.in_progress? || enrollment.completed?
      lesson_progresses = enrollment.lesson_progresses.includes(:lesson).map do |lp|
        { id: lp.id, lesson_id: lp.lesson_id, status: lp.status, progress: lp.progress, watched_seconds: lp.watched_seconds }
      end

      completed_count = enrollment.lesson_progresses.where(status: :completed).count
      progress_percentage = total_lessons > 0 ? (completed_count.to_f / total_lessons * 100).round(2) : 0
    end

    render json: {
      enrollment: enrollment,
      progress_percentage: progress_percentage,
      total_lessons: total_lessons,
      lesson_progresses: lesson_progresses
    }
  end

  private

  def filter_params
    permitted = params.permit(:search, :status)

    role = params[:role]
    allowed_roles = %w[admin student]
    if role.present? && allowed_roles.include?(role)
      permitted[:role] = role
    end

    permitted
  end

  def sort_params
    allowed = %w[first_name email status role]
    priority_order = [ "status", "role", "first_name", "email" ]
    sort = params[:sort].to_s

    return nil if sort.blank?

    parts = sort.split(",")
    reordered = parts.sort_by do |part|
      field = part.delete_prefix("-")
      priority_order.index(field) || 999
    end

    clauses = reordered.map do |p|
      dir = p.start_with?("-") ? "DESC" : "ASC"
      field = p.delete_prefix("-")
      next unless allowed.include?(field)
      "#{field} #{dir}"
    end.compact

    clauses.join(", ")
  end

  def user_delete_params
    params.permit(user_ids: [])
  end

  def user_result(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      role: user.role,
      created_at: user.created_at,
      status: User.statuses[user.status],
      avatar: user.avatar.attached? ? rails_blob_url(user.avatar, host: request.base_url) : nil,
      admin: user.admin.present? ? { id: user.admin.id, first_name: user.admin.first_name, last_name: user.admin.last_name, email: user.admin.email } : nil
    }
  end
end
