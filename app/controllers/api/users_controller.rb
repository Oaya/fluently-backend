class Api::UsersController < ApplicationController
  before_action :authenticate_api_user!
  before_action :require_admin_or_instructor!, only: [ :index, :courses, :instructors ]
  before_action :require_admin!, :require_active_tenant!, only: [  :bulk_delete ]

  # GET /api/users
  def index
    users = Current.tenant.users.filtering(filter_params).includes(:membership)

    users = users.order(sort_params) if sort_params.present?

    render json: users.map { |user|
      user_result(user)
    }
  end

  # GET /api/users/:id
  def show
    user = Current.tenant.users.find(params[:id])
      render json: user_result(user)
  end

  # GET /api/users/instructors
  def instructors
    users = Current.tenant.users.joins(:membership).where(memberships: { role: :instructor }).order(first_name: :desc)

    render json: users.map { |user|
      {
        id: user.id,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        avatar: user.avatar.attached? ? rails_blob_url(user.avatar, host: request.base_url) : nil
      }
    }
  end

  # DELETE /api/users/bulk_delete
  def bulk_delete
    pp params
    user_ids = user_delete_params[:user_ids] || []
    unless user_ids.is_a?(Array)
      return render_error("user_ids must be an array", status: :bad_request)
    end

    # Only delete users within the current tenant
    users = Current.tenant.users.where(id: user_ids)

    # Prevent self-deletion
    users = users.where.not(id: current_api_user.id)

    # Delete memberships and users
    # (dependent: :destroy could handle this, but being explicit here)
    Membership.where(user_id: users.pluck(:id)).delete_all
    deleted_count = users.delete_all

    render json: { deleted_count: deleted_count }, status: :ok
  end

  # GET /api/users/:id/courses
  # 1. get courses as instructor.

  def courses
    user = Current.tenant.users.find(params[:id])
    courses_as_instructor = Current.tenant
      .courses
      .joins(:course_instructors)
      .where(course_instructors: { instructor_id: user.id })
      .distinct
      .order(created_at: :desc)


    render json: courses_as_instructor.map { |course|
      {
        id: course.id,
        title: course.title,
        published: course.published
      }
    }
  end

  def enrollments
    user = Current.tenant.users.find(params[:id])
    enrollments = user.enrollments.includes(:course).order(created_at: :desc)

    render json: enrollments.map { |enrollment|
      {
        id: enrollment.id,
        status: enrollment.status,
        course: enrollment.course.as_json.merge(
          thumbnail: enrollment.course.thumbnail.attached? ? rails_blob_url(enrollment.course.thumbnail, host: request.base_url) : nil # rubocop:disable Lint/Syntax
        ),
        enrolled_at: enrollment.created_at
      }
    }
  end

  def course_status
    user = Current.tenant.users.find(params[:id])
    course = Current.tenant.courses.find(params[:course_id])
    enrollment = user.enrollments.find_by(course: course)

    unless enrollment
      return render_error("User is not enrolled in this course", status: :not_found)
    end

    total_lessons = Lesson.joins(section: :course).where(sections: { course_id: course.id }).count
    lesson_progresses = []
    progress_percentage = 0

    if enrollment.in_progress? || enrollment.completed?
      lesson_progresses = enrollment.lesson_progresses.includes(:lesson).map do |lp|
        { lesson_id: lp.lesson_id, status: lp.status, progress: lp.progress }
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
    if role.present? && Membership.roles.key?(role)
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
      role: Membership.roles[user.membership&.role],
      created_at: user.created_at,
      status: User.statuses[user.status],
      avatar: user.avatar.attached? ? rails_blob_url(user.avatar, host: request.base_url) : nil
    }
  end
end
