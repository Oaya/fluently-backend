class Api::HomeworkSubmissionsController < ApplicationController
  before_action :authenticate_api_user!
  before_action :set_submission, only: [ :show, :update, :destroy ]
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

    render json: submissions.map { |s| submission_result(s) }
  end

  # GET /api/homework_submissions/:id
  def show
    render json: submission_result(@submission)
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
      status: submission_params[:status] || "submitted",
      submitted_at: Time.current
    )

    pp submission_params


    ActiveRecord::Base.transaction do
      submission.save!
      handle_attachments!(submission, attachment_params)
    end

    render json: submission_result(submission.reload), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render_error(e.record.errors.full_messages, status: :unprocessable_entity)
  end

  # PATCH /api/homework_submissions/:id
  # Only the owning student can update, and only while not yet reviewed.
  def update
    return render_error("Not authorized", status: :forbidden) unless owner?
    return render_error("Cannot update a reviewed submission", status: :unprocessable_entity) if @submission.reviewed?

    attrs = submission_params.to_h.except("homework_id", "attachments")
    attrs["submitted_at"] = Time.current if attrs["status"] == "submitted" && @submission.submitted_at.nil?

    ActiveRecord::Base.transaction do
      @submission.update!(attrs)
      handle_attachments!(@submission, attachment_params)
    end

    render json: submission_result(@submission.reload)
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

  def handle_attachments!(submission, attachments)
    return if attachments.blank?

    attachments.each do |att|
      kind = att[:type].presence || att[:kind]
      record = submission.submission_attachments.build(kind: kind, url: att[:url])
      record.file.attach(att[:signed_id]) if att[:signed_id].present?
      record.save!
    end
  end

  def attachment_params
    params.permit(attachments: [ :kind, :url, :signed_id, :type ])[:attachments] || []
  end

  def submission_params
    params.require(:homework_submission).permit(
      :homework_id, :answer_text, :status,
      attachments: [ :kind, :url, :signed_id ]
    )
  end

  def submission_result(submission)
    {
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
      attachments: submission.submission_attachments.map { |a| attachment_result(a) }
    }
  end

  def attachment_result(attachment)
    {
      id: attachment.id,
      kind: attachment.kind,
      url: attachment.url || (attachment.file.attached? ? rails_blob_url(attachment.file, host: request.base_url) : nil)
    }
  end
end
