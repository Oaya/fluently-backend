class MakeEnrollmentCourseOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :enrollments, :course_id, true
  end
end
