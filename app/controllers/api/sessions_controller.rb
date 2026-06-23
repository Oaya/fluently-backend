class Api::SessionsController < ApplicationController
  before_action :authenticate_api_user!
  before_action :require_admin!, :require_active_subscription!, only: [ :create, :update, :destroy ]
  before_action :set_session, only: [ :update, :destroy ]
  include Rails.application.routes.url_helpers

  # GET /api/sessions
  # If the current_api_user is admin return all the sessions for the students.
  # If students, then return their only sessions
  def index
    sessions = if current_api_user.role == "admin"
      Session.includes(:student, :admin).all
    else
      Session.includes(:student, :admin).where(student: current_api_user)
    end

    sessions = sessions.order(scheduled_at: :desc)

    render json: sessions.map { |s| session_result(s) }
  end

  # POST /api/sessions
  def create
    session = Session.new(session_params.merge(admin: current_api_user))

    if session.save
      render json: session_result(session), status: :created
    else
      render_error(session.errors.full_messages, status: :unprocessable_entity)
    end
  end



  # PATCH /api/sessions/:id
  def update
    if @session.update(session_params)
      render json: session_result(@session)
    else
      render_error(@session.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # DELETE /api/sessions/:id
  def destroy
    @session.destroy
    head :no_content
  end

  private

  def set_session
    @session = Session.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("Session not found", status: :not_found)
  end




  def session_params
    params.require(:session).permit(
      :student_id, :scheduled_at, :duration_in_minutes,
      :status, :topic, :note, :payment_status
    )
  end

  def session_result(session)
    {
      id: session.id,
      scheduled_at: session.scheduled_at,
      duration_in_minutes: session.duration_in_minutes,
      status: session.status,
      topic: session.topic,
      note: session.note,
      payment_status: session.payment_status,
      created_at: session.created_at,
      updated_at: session.updated_at,
      student: {
        id: session.student.id,
        first_name: session.student.first_name,
        last_name: session.student.last_name,
        email: session.student.email
      },
      admin: {
        id: session.admin.id,
        first_name: session.admin.first_name,
        last_name: session.admin.last_name,
        email: session.admin.email
      }
    }
  end
end
