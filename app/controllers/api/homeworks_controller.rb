class Api::HomeWorksController < ApplicationController
  before_action :authenticate_api_user!
  before_action :require_admin!, :require_active_subscription!, only: [ :create, :update, :destroy ]
  before_action :set_homework, only: [ :update, :destroy ]
  include Rails.application.routes.url_helpers

  # GET /api/homeworks
  # If the current_api_user is admin return all the homeworks for the students.
  # If students, then return their only homeworks
  def index
    homeworks = if current_api_user.role == "admin"
      HomeWork.includes(:student, :admin).all
    else
      HomeWork.includes(:student, :admin).where(student: current_api_user)
    end

    homeworks = homeworks.order(created_at: :desc)

    render json: homeworks.map { |s| homeworks_result(s) }
  end

  # POST /api/homeworks
  def create
    homework = Homework.new(homework_params.merge(admin: current_api_user))

    if homework.save
      render json: homework_result(homework), status: :created
    else
      render_error(homework.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # PATCH /api/homeworks/:id
  def update
    if @homework.update(homework_params)
      render json: homework_result(@homework)
    else
      render_error(@homework.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # DELETE /api/homeworks/:id
  def destroy
    @homework.destroy
    head :no_content
  end


  private

  def set_homework
    @homework = homework.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("homework not found", status: :not_found)
  end

  def homework_params
    params.require(:homework).permit(
      :student_id, :title, :instructions,
      :language, :level, :due_date
    )
  end

  def homework_result(homework)
    {
      id: homework.id,
      due_date: homework.due_date,
      title: homework.title,
      status: homework.status,
      instructions: homework.instructions,
      submitted_at: homework.submitted_at,
      reviewed_at: homework.reviewed_at,
      language: homework.language,
      level: homework.level,
      ai_generated: homework.ai_generated,
      student: {
        id: homework.student.id,
        first_name: homework.student.first_name,
        last_name: homework.student.last_name,
        avatar: homework.student.avatar.attached? ? rails_blob_url(homework.student.avatar, host: request.base_url) : nil
      }
    }
  end
end
