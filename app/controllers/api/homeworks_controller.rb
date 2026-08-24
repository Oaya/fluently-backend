class Api::HomeworksController < ApplicationController
  before_action :authenticate_api_user!
  before_action :require_admin!, :require_active_subscription!, only: [ :create, :update, :destroy, :ai_generate ]
  before_action :require_pro_plan!, only: [ :ai_generate ]
  before_action :set_homework, only: [ :show, :update, :destroy ]
  include Rails.application.routes.url_helpers

  # GET /api/homeworks
  # If the current_api_user is admin return the homeworks for their own students.
  # If students, then return their only homeworks
  def index
    homeworks = if current_api_user.admin?
      scope = current_api_user.homeworks_as_admin.includes(:student, :admin, homework_submission: { submission_attachments: { file_attachment: :blob } })
      params[:student_id].present? ? scope.where(student_id: params[:student_id]) : scope
    else
      current_api_user.homeworks.includes(:student, :admin, homework_submission: { submission_attachments: { file_attachment: :blob } })
    end

    homeworks = homeworks.order(created_at: :asc)

    render json: homeworks.map { |h| HomeworkSerializer.new(h, current_api_user.role, host: request.base_url).homework_result }
  end

  # GET /api/homeworks/:id
  def show
    render json: HomeworkSerializer.new(@homework, current_api_user.role, host: request.base_url).homework_result, status: :ok
  end

  # POST /api/homeworks
  def create
    student = current_api_user.students.find_by(id: homework_params[:student_id])
    return render_error("Student not found", status: :not_found) unless student

    homework = Homework.new(homework_params.merge(admin: current_api_user))

    if homework.save
      render json: HomeworkSerializer.new(homework, current_api_user.role, host: request.base_url).homework_result, status: :created
    else
      render_error(homework.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # PATCH /api/homeworks/:id
  def update
    if homework_params[:student_id].present? && !current_api_user.students.exists?(id: homework_params[:student_id])
      return render_error("Student not found", status: :not_found)
    end

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

  # POST /api/homeworks/ai_generate
  def ai_generate
    student = current_api_user.students.find_by(id: ai_generate_params[:student_id])
    return render_error("Student not found", status: :not_found) unless student

    generated = GenerateHomeworkWithAi.new(
      language: ai_generate_params[:language],
      level: ai_generate_params[:level],
      exercise_type: ai_generate_params[:exercise_type],
      topics: ai_generate_params[:topics] || [],
      notes: ai_generate_params[:notes]
    ).call

    render json: generated, status: :ok
  rescue => e
    render_error("AI generation failed: #{e.message}", status: :unprocessable_entity)
  end


  private

  def set_homework
    scope = current_api_user.admin? ? current_api_user.homeworks_as_admin : current_api_user.homeworks
    @homework = scope.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("homework not found", status: :not_found)
  end

  def homework_params
    params.require(:homework).permit(
      :student_id, :title, :instructions,
      :language, :level, :due_date, :ai_generated
    )
  end

  def ai_generate_params
    params.permit(:student_id, :language, :level, :exercise_type, :notes, topics: [])
  end
end
