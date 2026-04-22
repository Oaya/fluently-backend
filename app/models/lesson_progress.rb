class LessonProgress < ApplicationRecord
  belongs_to :enrollment
  belongs_to :tenant
  belongs_to :lesson

  validates :lesson_id, uniqueness: { scope: :enrollment_id }

  enum :status, { not_started: "not_started", in_progress: "in_progress", completed: "completed" }
end
