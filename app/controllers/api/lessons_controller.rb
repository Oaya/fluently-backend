class Api::LessonsController < ApplicationController
  before_action :authenticate_api_user!
  before_action :require_admin!, :require_active_subscription!, only: [ :create, :update, :destroy, :cancel ]
  before_action :set_lesson, only: [ :update, :destroy, :cancel, :end ]
  include Rails.application.routes.url_helpers

  # GET /api/lessons
  def index
    lessons = if current_api_user.role == "admin"
      scope = Lesson.includes(:student, :admin)
      params[:student_id].present? ? scope.where(student_id: params[:student_id]) : scope.all
    else
      Lesson.includes(:student, :admin).where(student: current_api_user)
    end

    lessons = lessons.order(scheduled_at: :asc)
    render json: lessons.map { |l| lesson_result(l) }
  end

  # GET /api/lessons/:id
  def show
    lesson = Lesson.find(params[:id])
    render json: lesson_result(lesson), status: :ok
  end

  # POST /api/lessons
  def create
    lesson = Lesson.new(lesson_params.merge(admin: current_api_user))

    if lesson.save
      render json: lesson_result(lesson), status: :created
    else
      render_error(lesson.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # PATCH /api/lessons/:id
  def update
    if @lesson.update(lesson_params)
      render json: lesson_result(@lesson)
    else
      render_error(@lesson.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # PATCH /api/lessons/:id/cancel
  def cancel
    if @lesson.update(status: "canceled")
      render json: lesson_result(@lesson)
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
    lessons = if current_api_user.role == "admin"
      Lesson.includes(:student, :admin).where(scheduled_at: today_range)
    else
      Lesson.includes(:student, :admin).where(student: current_api_user, scheduled_at: today_range)
    end

    lessons = lessons.order(scheduled_at: :asc)

    render json: lessons.map { |l| lesson_result(l) }
  end


  def token
    user = Current.user
    lesson = Lesson.find(params[:id])
    is_admin = user.admin?
    identity = "user-#{user.id}"
    name = "#{user.first_name} #{user.last_name}"

    jwt = LivekitTokenService.generate(
      room_name: lesson.room_name,
      identity: identity,
      name: name,
      is_admin: is_admin
    )

    render json: {
      token: jwt,
      url: ENV["LIVEKIT_URL"],
      room_name: lesson.room_name
    }
  end

  # PATCH /api/lessons/:id/end
  def end
    if @lesson.update(lesson_meeting_params)
      render json: lesson_result(@lesson)
    else
      render_error(@lesson.errors.full_messages, status: :unprocessable_entity)
    end
  end

  private

  def set_lesson
    @lesson = Lesson.find(params[:id])
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

  def lesson_result(lesson)
    {
      id: lesson.id,
      scheduled_at: lesson.scheduled_at,
      duration_in_minutes: lesson.duration_in_minutes,
      status: lesson.status,
      topic: lesson.topic,
      note: lesson.note,
      language: lesson.language,
      payment_status: lesson.payment_status,
      created_at: lesson.created_at,
      updated_at: lesson.updated_at,
      room_name: lesson.room_name,
      meeting_duration_in_seconds: lesson.meeting_duration_in_seconds,
      meeting_feedback: lesson.meeting_feedback,
      student: {
        id: lesson.student.id,
        first_name: lesson.student.first_name,
        last_name: lesson.student.last_name,
        avatar: lesson.student.avatar.attached? ? rails_blob_url(lesson.student.avatar, host: request.base_url) : nil,
        email: lesson.student.email,
        learning_languages: lesson.student.learning_languages
      }
    }
  end
end
