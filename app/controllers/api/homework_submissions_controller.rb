class Api::HomeworkSubmissionsController < ApplicationController
  before_action :authenticate_api_user!
  before_action :set_submission, only: [ :show, :destroy ]
  before_action :require_admin!, :require_active_subscription!, only: [ :feedback ]
  include Rails.application.routes.url_helpers

  # GET /api/homework_submissions
  # Admin: all submissions (optionally filtered by homework_id)
  # Student: only their own submissions
  def index
    submissions = if current_api_user.role == "admin"
      HomeworkSubmission.includes(:student, :homework, submission_attachments: { file_attachment: :blob })
    else
      HomeworkSubmission.includes(:student, :homework, submission_attachments: { file_attachment: :blob })
                        .where(student: current_api_user)
    end

    submissions = submissions.where(homework_id: params[:homework_id]) if params[:homework_id].present?
    submissions = submissions.order(created_at: :asc)

    render json: submissions.map { |s| submission_result(s, current_api_user.role) }
  end

  # GET /api/homework_submissions/:id
  def show
    render json: submission_result(@submission, current_api_user.role)
  end

  # POST /api/homework_submissions
  # Students only. One submission per student per homework (find or create).
  def create
    return render_error("Only students can submit homework", status: :forbidden) if current_api_user.role == "admin"

    submission = HomeworkSubmission.find_or_initialize_by(
      homework_id: submission_params[:homework_id],
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

    render json: submission_result(submission.reload, current_api_user.role), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render_error(e.record.errors.full_messages, status: :unprocessable_entity)
  end


  # PATCH /api/homework_submissions/:id/feedback
  # Admin only. One submission per student per homework (find or create).
  def feedback
    submission = HomeworkSubmission.find(params[:id])
    return render_error("Cannot give feedback submission", status: :unprocessable_entity) if !submission.persisted?

    submission.assign_attributes(
      feedback: feedback_params[:feedback],
      score: feedback_params[:score],
      notes: feedback_params[:notes],
      reviewed_at: Time.current,
      status: "reviewed"
    )

    submission.save!
    render json: submission_result(submission.reload, current_api_user.role), status: :created
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
    scope = current_api_user.role == "admin" ? HomeworkSubmission : HomeworkSubmission.where(student: current_api_user)
    @submission = scope.includes(submission_attachments: { file_attachment: :blob }).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("Submission not found", status: :not_found)
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

  def submission_result(submission, role)
    result = {
      id: submission.id,
      homework_id: submission.homework_id,
      answer_text: submission.answer_text,
      status: submission.status,
      submitted_at: submission.submitted_at,
      reviewed_at: submission.reviewed_at,
      student: {
        id: submission.student.id,
        first_name: submission.student.first_name,
        last_name: submission.student.last_name
      },
      attachments: submission.submission_attachments.map { |a|
        {
          id: a.id,
          type: a.type,
          filename: a.file.attached? ? a.file.filename.to_s : nil,
          url: a.url || (a.file.attached? ? rails_blob_url(a.file, host: request.base_url, disposition: "attachment") : nil),
          sub: a.sub
        }
      },
      feedback: submission.feedback,
      score: submission.score
    }
    result[:notes] = submission.notes if role == "admin"

    result
  end
end
