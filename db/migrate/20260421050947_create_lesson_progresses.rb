class CreateLessonProgresses < ActiveRecord::Migration[8.1]
  def change
    create_table :lesson_progresses, id: :uuid do |t|
      t.timestamps
      t.references :tenant, type: :uuid, null: false, foreign_key: true
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :course, type: :uuid, null: false, foreign_key: true
      t.references :lesson, type: :uuid, null: false, foreign_key: true
      t.references :section, type: :uuid, null: false, foreign_key: true
      t.integer :progress, null: false, default: 0
      t.string :status, null: false, default: "not_started"
    end

    add_column :enrollments, :last_accessed_lesson_id, :uuid
    add_foreign_key :enrollments, :lessons, column: :last_accessed_lesson_id
    add_column :enrollments, :overall_progress, :integer, null: false, default: 0
  end
end
