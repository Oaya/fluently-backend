class RemoveCourseFromEnrollment < ActiveRecord::Migration[8.1]
  def change
    remove_index "enrollments", name: "index_enrollments_on_course_id", if_exists: true
    remove_index "enrollments", name: "index_enrollments_on_user_id_and_course_id", if_exists: true

    remove_column "enrollments", "course_id", :uuid

    add_column :enrollments, :level, :string, null: true
  end
end
