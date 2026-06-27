class Homework < ApplicationRecord
  belongs_to :student, class_name: "User"
  belongs_to :admin,   class_name: "User"

  enum :status, {
    pending: "pending",
    submitted: "submitted",
    overdue: "overdue",
    reviewed: "reviewed"
  }, validate: true

  validates :due_date, :status, :title, presence: true
  validates :ai_generated, inclusion: { in: [ true, false ] }
end
