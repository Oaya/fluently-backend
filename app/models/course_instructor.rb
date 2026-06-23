class CourseInstructor < ApplicationRecord
  belongs_to :course

  validates :course_id, presence: true
end
