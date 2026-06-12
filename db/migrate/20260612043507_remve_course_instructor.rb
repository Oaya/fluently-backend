class RemveCourseInstructor < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key "course_instructors", "courses"
    remove_foreign_key "course_instructors", "users", column: "instructor_id"

    remove_index "course_instructors", name: "index_course_instructors_on_course_id_and_instructor_id"
    remove_index "course_instructors", name: "index_course_instructors_on_instructor_id"

    drop_table "course_instructors"
  end
end
