class Api::LessonsController < ApplicationController
  before_action :authenticate_api_user!
  before_action :require_admin!, :require_active_subscription!, only: [ :create, :update, :destroy ]
  before_action :set_lesson, only: [ :show, :update, :destroy, :end, :student_note, :token ]
  include Rails.application.routes.url_helpers

  # GET /api/lessons
  def index
    lessons = if current_api_user.admin?
      scope = current_api_user.lessons_as_admin.includes(:student, :admin)
      params[:student_id].present? ? scope.where(student_id: params[:student_id]) : scope
    else
      current_api_user.lessons_as_student.includes(:student, :admin)
    end

    lessons = lessons.order(scheduled_at: :desc)
    render json: lessons.map { |l| LessonSerializer.new(l, host: request.base_url, current_user: current_api_user).lesson_result }
  end

  # GET /api/lessons/:id
  def show
    render json: LessonSerializer.new(@lesson, host: request.base_url, current_user: current_api_user).lesson_result, status: :ok
  end

  # POST /api/lessons
  def create
    student = current_api_user.students.find_by(id: lesson_params[:student_id])
    return render_error("Student not found", status: :not_found) unless student

    lesson = Lesson.new(lesson_params.merge(admin: current_api_user))

    if lesson.save
      render json: LessonSerializer.new(lesson, host: request.base_url, current_user: current_api_user).lesson_result, status: :created
    else
      render_error(lesson.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # PATCH /api/lessons/:id
  def update
    if lesson_params[:student_id].present? && !current_api_user.students.exists?(id: lesson_params[:student_id])
      return render_error("Student not found", status: :not_found)
    end

    if @lesson.update(lesson_params)
      render json: LessonSerializer.new(@lesson, host: request.base_url, current_user: current_api_user).lesson_result
    else
      render_error(@lesson.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # DELETE /api/lessons/:id
  def destroy
    @lesson.destroy
    head :no_content
  end

  # GET /api/lessons/today
  def today
    tz = ActiveSupport::TimeZone[current_api_user.timezone || "UTC"] || ActiveSupport::TimeZone["UTC"]
    today_range = tz.now.beginning_of_day..tz.now.end_of_day
    lessons = if current_api_user.admin?
      current_api_user.lessons_as_admin.includes(:student, :admin).where(scheduled_at: today_range)
    else
      current_api_user.lessons_as_student.includes(:student, :admin).where(scheduled_at: today_range)
    end

    lessons = lessons.order(scheduled_at: :asc)

    render json: lessons.map { |l| LessonSerializer.new(l, host: request.base_url, current_user: current_api_user).lesson_result }
  end


  def token
    user = current_api_user
    is_admin = user.admin?
    identity = "user-#{user.id}"
    name = "#{user.first_name} #{user.last_name}"

    jwt = LivekitTokenService.generate(
      room_name: @lesson.room_name,
      identity: identity,
      name: name,
      is_admin: is_admin
    )

    render json: {
      token: jwt,
      url: ENV["LIVEKIT_URL"],
      room_name: @lesson.room_name
    }
  end

  # PATCH /api/lessons/:id/end
  def end
    if @lesson.update(lesson_meeting_params)
      render json: LessonSerializer.new(@lesson, host: request.base_url, current_user: current_api_user).lesson_result
    else
      render_error(@lesson.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # PATCH /api/lessons/:id/student_note
  def student_note
    unless current_api_user.role == "student" && @lesson.student_id == current_api_user.id
      return render_error("No permission to access", status: :forbidden)
    end

    if @lesson.update(student_note_params)
      render json: LessonSerializer.new(@lesson, host: request.base_url, current_user: current_api_user).lesson_result
    else
      render_error(@lesson.errors.full_messages, status: :unprocessable_entity)
    end
  end

  private

  def set_lesson
    scope = current_api_user.admin? ? current_api_user.lessons_as_admin : current_api_user.lessons_as_student
    @lesson = scope.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("Lesson not found", status: :not_found)
  end

  def lesson_params
    params.require(:lesson).permit(
      :student_id, :scheduled_at, :duration_in_minutes,
      :status, :topic, :note, :payment_status, :language
    )
  end

  def lesson_meeting_params
    params.require(:lesson).permit(
      :meeting_duration_in_seconds, :status, :meeting_feedback
    )
  end

  def student_note_params
    params.require(:lesson).permit(:student_note)
  end
end
