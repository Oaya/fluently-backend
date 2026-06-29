class HomeworkSubmission < ApplicationRecord
  belongs_to :student, class_name: "User"
  belongs_to :homework
  has_many :submission_attachments, dependent: :destroy

  enum :status, {
    draft: "draft",
    submitted: "submitted",
    reviewed: "reviewed"
  }, validate: true

  validates :status, presence: true
end
