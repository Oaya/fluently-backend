class AddWatchedSecondsToLessonProgresses < ActiveRecord::Migration[8.0]
  def change
    add_column :lesson_progresses, :watched_seconds, :integer, default: 0, null: false
  end
end
