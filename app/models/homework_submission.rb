class HomeworkSubmission < ApplicationRecord
  belongs_to :student, class_name: "User"
  belongs_to :homework
  has_many :submission_attachments, dependent: :destroy

  enum :status, {
    draft: "draft",
    submitted: "submitted",
    reviewed: "reviewed"
  }, validate: true


  enum :score, {
    needs_work: "needs_work",
    good: "good",
    excellent: "excellent"
  }

  validates :status, presence: true
end
