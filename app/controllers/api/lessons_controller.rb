class Api::LessonsController < ApplicationController
  before_action :authenticate_api_user!
  before_action :require_admin!, :require_active_subscription!, only: [ :create, :update, :destroy, :end, :meeting_note ]
  before_action :set_lesson, only: [ :show, :update, :destroy, :end, :student_note, :meeting_note, :token, :cancel ]
  include Rails.application.routes.url_helpers

  # GET /api/lessons
  def index
    lessons = if current_api_user.admin?
      scope = current_api_user.lessons_as_admin.includes(:student, :admin, :invoice)
      params[:student_id].present? ? scope.where(student_id: params[:student_id]) : scope
    else
      current_api_user.lessons_as_student.includes(:student, :admin, :invoice)
    end

    lessons = lessons.order(scheduled_at: :desc)
    render_lessons(lessons)
  end

  # GET /api/lessons/:id
  def show
    render_lesson(@lesson)
  end

  # POST /api/lessons
  def create
    student = current_api_user.students.find_by(id: lesson_params[:student_id])
    return render_error("Student not found", status: :not_found) unless student

    errors = []
    errors << "Student has no lesson rate set. Please edit the student profile first." if student.lesson_rate.blank?
    errors << "Your account has no currency set. Please edit the your profile first." if current_api_user.currency.blank?
    errors << "Your account has no timezone set. Please update your profile first." if current_api_user.timezone.blank?
    errors << "Student has no timezone set. Please edit the student profile first." if student.timezone.blank?
    return render_error(errors, status: :unprocessable_entity) if errors.any?

    lesson = Lesson.new(lesson_params.merge(admin: current_api_user))

    if lesson.save
      render_lesson(lesson, status: :created)
    else
      render_error(lesson.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # PATCH /api/lessons/:id
  def update
    if lesson_params[:student_id].present? && !current_api_user.students.exists?(id: lesson_params[:student_id])
      return render_error("Student not found", status: :not_found)
    end

    extra_attrs = LessonFeeCalculator.new.no_show_fee_attrs(@lesson, lesson_params[:status])

    if @lesson.update(lesson_params.merge(extra_attrs))
      render_lesson(@lesson)
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

    render_lessons(lessons)
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
    extra_attrs = LessonFeeCalculator.new.no_show_fee_attrs(@lesson, lesson_meeting_params[:status])

    if @lesson.update(lesson_meeting_params.merge(extra_attrs))
      render_lesson(@lesson)
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
      render_lesson(@lesson)
    else
      render_error(@lesson.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # PATCH /api/lessons/:id/cancel
  def cancel
    unless current_api_user.role == "student" && @lesson.student_id == current_api_user.id
      return render_error("No permission to access", status: :forbidden)
    end

    unless @lesson.status == "scheduled"
      return render_error("Only scheduled lessons can be cancelled", status: :unprocessable_entity)
    end

    attrs = { status: "canceled" }.merge(LessonFeeCalculator.new.late_cancellation_fee_attrs(@lesson))

    if @lesson.update(attrs)
      render_lesson(@lesson)
    else
      render_error(@lesson.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # PATCH /api/lessons/:id/meeting_note
  def meeting_note
    unless current_api_user.role == "admin" && @lesson.admin_id == current_api_user.id
      return render_error("No permission to access", status: :forbidden)
    end

    if @lesson.update(meeting_note_params)
      render json: { meeting_note: @lesson.meeting_note }
    else
      render_error(@lesson.errors.full_messages, status: :unprocessable_entity)
    end
  end

  private

  def render_lesson(lesson, status: :ok)
    render json: LessonSerializer.new(lesson, host: request.base_url, current_user: current_api_user).lesson_result, status: status
  end

  def render_lessons(lessons)
    render json: lessons.map { |l| LessonSerializer.new(l, host: request.base_url, current_user: current_api_user).lesson_result }
  end

  def set_lesson
    scope = current_api_user.admin? ? current_api_user.lessons_as_admin : current_api_user.lessons_as_student
    @lesson = scope.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("Lesson not found", status: :not_found)
  end

  def lesson_params
    params.require(:lesson).permit(
      :student_id, :scheduled_at, :duration_in_minutes,
      :status, :topic, :teacher_note, :language
    )
  end

  def lesson_meeting_params
    params.require(:lesson).permit(
      :meeting_duration_in_seconds, :status, :meeting_feedback, :meeting_note, :note_shared
    )
  end

  def student_note_params
    params.require(:lesson).permit(:student_note)
  end

  def meeting_note_params
    params.require(:lesson).permit(:meeting_note)
  end
end
