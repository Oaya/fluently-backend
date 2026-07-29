class CreateLessonRecordings < ActiveRecord::Migration[8.1]
  def change
    create_table :lesson_recordings, id: :uuid do |t|
      t.references :lesson, null: false, foreign_key: true, type: :uuid, index: false
      t.integer :duration_in_seconds
      t.integer :file_size

      t.timestamps
    end
  end
end
