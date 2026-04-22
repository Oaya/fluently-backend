class RemoveReferenceFromLessonProgresses < ActiveRecord::Migration[8.1]
  def change
    remove_reference :lesson_progresses, :course, type: :uuid, foreign_key: true
    remove_reference :lesson_progresses, :user, type: :uuid, foreign_key: true
    remove_reference :lesson_progresses, :section, type: :uuid, foreign_key: true
  end
end