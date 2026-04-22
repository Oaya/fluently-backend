class AddUniqueIndexToLessonProgresses < ActiveRecord::Migration[8.1]
  def change
    add_index :lesson_progresses,
          [:enrollment_id, :lesson_id],
          unique: true,
          name: "index_lesson_progresses_on_enrollment_and_lesson"
  end
end
