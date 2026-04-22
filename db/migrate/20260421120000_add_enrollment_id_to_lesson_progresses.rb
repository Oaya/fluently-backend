class AddEnrollmentIdToLessonProgresses < ActiveRecord::Migration[8.1]
  def up
    add_reference :lesson_progresses, :enrollment, type: :uuid, foreign_key: true, index: false

    execute <<-SQL.squish
      UPDATE lesson_progresses lp
      SET enrollment_id = e.id
      FROM enrollments e
      WHERE lp.user_id = e.user_id
        AND lp.course_id = e.course_id
        AND lp.tenant_id = e.tenant_id
        AND lp.enrollment_id IS NULL
    SQL

    # Rows that could not be matched to an enrollment cannot satisfy NOT NULL.
    LessonProgress.where(enrollment_id: nil).delete_all

    change_column_null :lesson_progresses, :enrollment_id, false
    add_index :lesson_progresses, [ :enrollment_id, :lesson_id ],
      unique: true,
      name: "index_lesson_progresses_on_enrollment_id_and_lesson_id"
  end

  def down
    remove_index :lesson_progresses, name: "index_lesson_progresses_on_enrollment_id_and_lesson_id"
    remove_reference :lesson_progresses, :enrollment, type: :uuid, foreign_key: true
  end
end
