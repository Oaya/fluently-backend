class HomeworkSerializer
  include Rails.application.routes.url_helpers

  def initialize(homework, role, host:)
    @homework = homework
    @role = role
    @host = host
  end

  def homework_result
    sub = @homework.homework_submission
    result = {
      id: @homework.id,
      due_date: @homework.due_date,
      title: @homework.title,
      instructions: @homework.instructions,
      language: @homework.language,
      level: @homework.level,
      ai_generated: @homework.ai_generated,
      status: homework_status_badge(@homework),
      student: {
        id: @homework.student.id,
        first_name: @homework.student.first_name,
        last_name: @homework.student.last_name,
        avatar: UserSerializer.new(@homework.student, host: @host).avatar_url,
        learning_languages: @homework.student.learning_languages
      },
      submission: sub && submission_result(sub)
    }

    result
  end


  def submission_result(submission = @homework)
    result = {
      id: submission.id,
      homework_id: submission.homework_id,
      answer_text: submission.answer_text,
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
          url: a.url || attachment_url(a),
          sub: a.sub
        }
      },
      feedback: submission.status == "reviewed" ? {
        feedback_text: submission.feedback,
        score: submission.score,
        **(@role == "admin" ? { notes: submission.notes } : {})
      } : nil
    }

    result
  end



  def homework_status_badge(homework)
    sub = homework.homework_submission
    return "pending" if !sub
    return sub.status if %w[submitted reviewed].include?(sub.status)

    overdue = homework.due_date.present? && homework.due_date.to_date < Date.today
    overdue ? "overdue" : sub.status
  end

  private

  def attachment_url(attachment)
    return nil unless attachment.file.attached?
    rails_blob_url(attachment.file, host: @host)
  end
end
