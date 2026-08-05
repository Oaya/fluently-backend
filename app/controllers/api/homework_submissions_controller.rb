class Api::HomeworkSubmissionsController < ApplicationController
  before_action :authenticate_api_user!
  before_action :set_submission, only: [ :show, :destroy, :feedback ]
  before_action :require_admin!, :require_active_subscription!, only: [ :feedback ]
  include Rails.application.routes.url_helpers

  # GET /api/homework_submissions
  # Admin: submissions for their own students (optionally filtered by homework_id)
  # Student: only their own submissions
  def index
    submissions = accessible_submissions.includes(:student, :homework, submission_attachments: { file_attachment: :blob })

    submissions = submissions.where(homework_id: params[:homework_id]) if params[:homework_id].present?
    submissions = submissions.order(created_at: :asc)

    render json: submissions.map { |h| HomeworkSerializer.new(h, current_api_user.role, host: request.base_url).submission_result }
  end

  # GET /api/homework_submissions/:id
  def show
    render json: HomeworkSerializer.new(@submission, current_api_user.role, host: request.base_url).submission_result
  end

  # POST /api/homework_submissions
  # Students only. One submission per student per homework (find or create).
  def create
    return render_error("Only students can submit homework", status: :forbidden) if current_api_user.role == "admin"

    homework = current_api_user.homeworks.find_by(id: submission_params[:homework_id])
    return render_error("Homework not found", status: :not_found) unless homework

    submission = HomeworkSubmission.find_or_initialize_by(
      homework_id: homework.id,
      student: current_api_user
    )

    return render_error("Cannot update a reviewed submission", status: :unprocessable_entity) if submission.persisted? && submission.reviewed?

    submission.assign_attributes(
      answer_text: submission_params[:answer_text],
      status: submission_params[:status],
      submitted_at: submission_params[:status] == "submitted" ? Time.current : nil
    )

    ActiveRecord::Base.transaction do
      submission.save!
      handle_attachments!(submission, attachment_params, keep_attachment_ids)
    end

    render json: HomeworkSerializer.new(submission.reload, current_api_user.role, host: request.base_url).submission_result, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render_error(e.record.errors.full_messages, status: :unprocessable_entity)
  end


  # PATCH /api/homework_submissions/:id/feedback
  # Admin only, and only for their own students' submissions.
  def feedback
    @submission.assign_attributes(
      feedback: feedback_params[:feedback],
      score: feedback_params[:score],
      notes: feedback_params[:notes],
      reviewed_at: Time.current,
      status: "reviewed"
    )

    @submission.save!
    render json: HomeworkSerializer.new(@submission.reload, current_api_user.role, host: request.base_url).submission_result, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render_error(e.record.errors.full_messages, status: :unprocessable_entity)
  end

  # DELETE /api/homework_submissions/:id
  # Only the owning student can delete, and only while in draft.
  def destroy
    return render_error("Not authorized", status: :forbidden) unless owner?
    return render_error("Only draft submissions can be deleted", status: :unprocessable_entity) unless @submission.draft?

    @submission.destroy
    head :no_content
  end

  private

  def set_submission
    @submission = accessible_submissions.includes(submission_attachments: { file_attachment: :blob }).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("Submission not found", status: :not_found)
  end

  # Admin: submissions belonging to homeworks they assigned (i.e. their own students).
  # Student: only their own submissions.
  def accessible_submissions
    if current_api_user.admin?
      HomeworkSubmission.joins(:homework).where(homeworks: { admin_id: current_api_user.id })
    else
      HomeworkSubmission.where(student: current_api_user)
    end
  end

  def owner?
    @submission.student_id == current_api_user.id
  end

  def handle_attachments!(submission, attachments, keep_ids)
    existing = submission.submission_attachments.to_a

    # Delete attachments the frontend removed
    existing.each do |att|
      unless keep_ids.include?(att.id)
        att.file.purge if att.file.attached?
        att.destroy!
      end
    end

    # Create new attachments
    attachments.each do |att|
      record = submission.submission_attachments.build(type: att[:type].presence, url: att[:url], sub: att[:sub])
      record.file.attach(att[:signed_id]) if att[:signed_id].present?
      record.save!
    end
  end

  def attachment_params
    params.permit(attachments: [ :type, :url, :signed_id, :sub ])[:attachments] || []
  end

  def keep_attachment_ids
    params[:keep_attachment_ids] || []
  end

  def submission_params
    params.require(:homework_submission).permit(
      :homework_id, :answer_text, :status,
      attachments: [ :type, :url, :signed_id, :sub ]
    )
  end

  def feedback_params
    params.require(:homework_submission).permit(:score, :feedback, :notes)
  end
end
