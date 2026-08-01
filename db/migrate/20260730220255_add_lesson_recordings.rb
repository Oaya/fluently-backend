class AddLessonRecordings < ActiveRecord::Migration[8.1]
  def change
    create_table :lesson_recordings, id: :uuid do |t|
      t.references :lesson, null: false, foreign_key: true, type: :uuid

      t.bigint  :file_size          # bigint — videos can exceed integer range
      t.integer :duration_in_seconds

      t.timestamps
    end
  end
end
