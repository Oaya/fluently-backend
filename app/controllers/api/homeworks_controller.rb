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
      Homework.includes(:student, :admin, homework_submission: { submission_attachments: { file_attachment: :blob } }).all
    else
      Homework.includes(:student, :admin, homework_submission: { submission_attachments: { file_attachment: :blob } }).where(student: current_api_user)
    end

    homeworks = homeworks.order(created_at: :desc)

    render json: homeworks.map { |s| homework_result(s, current_api_user.role) }
  end

  # GET /api/homeworks/:id
  def show
    pp current_api_user.role
    homework = Homework.find(params[:id])
    render json: homework_result(homework, current_api_user.role), status: :ok
  end

  # POST /api/homeworks
  def create
    homework = Homework.new(homework_params.merge(admin: current_api_user))

    if homework.save
      render json: homework_result(homework, current_api_user.role), status: :created
    else
      render_error(homework.errors.full_messages, status: :unprocessable_entity)
    end
  end

  # PATCH /api/homeworks/:id
  def update
    pp homework_params
    if @homework.update(homework_params)
      render json: homework_result(@homework, current_api_user.role)
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

  def homework_result(homework, role)
    sub = homework.homework_submission
    result = {
      id: homework.id,
      due_date: homework.due_date,
      title: homework.title,
      instructions: homework.instructions,
      language: homework.language,
      level: homework.level,
      ai_generated: homework.ai_generated,
      student: {
        id: homework.student.id,
        first_name: homework.student.first_name,
        last_name: homework.student.last_name,
        avatar: homework.student.avatar.attached? ? rails_blob_url(homework.student.avatar, host: request.base_url) : nil,
        learning_languages: homework.student.learning_languages
      },
      submission: sub && {
        id: sub.id,
        status: sub.status,
        answer_text: sub.answer_text,
        submitted_at: sub.submitted_at,
        reviewed_at: sub.reviewed_at,
        attachments: sub.submission_attachments.map { |a|
          {
            id: a.id,
            type: a.type,
            filename: a.file.attached? ? a.file.filename.to_s : nil,
            url: a.url || (a.file.attached? ? rails_blob_url(a.file, host: request.base_url, disposition: "attachment") : nil),
            sub: a.sub
          }
        },
      feedback: sub.feedback,
      score: sub.score
      }
    }
    result[:submission][:notes] = sub.notes if role == "admin"

    result
  end
end
