class Enrollment < ApplicationRecord
  belongs_to :user

  has_many :lesson_progresses, dependent: :destroy

  enum :status, { enrolled: "enrolled", paused: "paused", canceled: "canceled" }

  def overall_progress
    total = Lesson.joins(section: :course).where(sections: { course_id: course_id }).count
    return 0 if total == 0

    completed = lesson_progresses.where(status: :completed).count
    (completed.to_f / total * 100).round
  end

  private
end
