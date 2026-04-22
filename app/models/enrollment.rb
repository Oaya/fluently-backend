class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :course
  belongs_to :tenant

  has_many :lesson_progresses, dependent: :destroy

  enum :status, { enrolled: "enrolled", in_progress: "in_progress", completed: "completed" }

  private
end
