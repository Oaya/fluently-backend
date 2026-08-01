class Api::HomeworksController < ApplicationController
  before_action :authenticate_api_user!
  before_action :require_admin!, :require_active_subscription!, only: [ :create, :update, :destroy ]
  before_action :set_homework, only: [ :update, :destroy ]
  include Rails.application.routes.url_helpers

  # GET /api/homeworks
  # If the current_api_user is admin return all the homeworks for the students.
  # If students, then return their only homeworks
  def index
    homeworks = if current_api_user.role == "admin"
      scope = Homework.includes(:student, :admin, homework_submission: { submission_attachments: { file_attachment: :blob } }).all
            params[:student_id].present? ? scope.where(student_id: params[:student_id]) : scope.all
    else
      Homework.includes(:student, :admin, homework_submission: { submission_attachments: { file_attachment: :blob } }).where(student: current_api_user)
    end

    homeworks = homeworks.order(created_at: :asc)

    render json: homeworks.map { |h| HomeworkSerializer.new(h, current_api_user.role, host: request.base_url).homework_result }
  end

  # GET /api/homeworks/:id
  def show
    pp current_api_user.role
    homework = Homework.find(params[:id])
    render json: HomeworkSerializer.new(homework, current_api_user.role, host: request.base_url).homework_result, status: :ok
  end

  # POST /api/homeworks
  def create
    homework = Homework.new(homework_params.merge(admin: current_api_user))

    if homework.save
      render json: HomeworkSerializer.new(homework, current_api_user.role, host: request.base_url).homework_result, status: :created
    else
      render_error(homework.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # PATCH /api/homeworks/:id
  def update
    pp homework_params
    if @homework.update(homework_params)
      render json: HomeworkSerializer.new(@homework, current_api_user.role, host: request.base_url).homework_result
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
    @homework = Homework.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("homework not found", status: :not_found)
  end

  def homework_params
    params.require(:homework).permit(
      :student_id, :title, :instructions,
      :language, :level, :due_date, :ai_generated
    )
  end
end
