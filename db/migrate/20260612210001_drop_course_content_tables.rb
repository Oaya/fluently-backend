class DropCourseContentTables < ActiveRecord::Migration[8.1]
  def up
    # Remove FK on enrollments pointing to lessons before dropping lessons
    remove_foreign_key :enrollments, :lessons
    remove_column :enrollments, :last_accessed_lesson_id

    drop_table :lesson_progresses
    drop_table :lessons
    drop_table :sections
    drop_table :courses
  end

  def down
    create_table :courses, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :category
      t.string :description, null: false
      t.string :level
      t.decimal :price, precision: 10, scale: 2
      t.boolean :published, default: false
      t.string :title, null: false
      t.timestamps
    end

    create_table :sections, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :course_id, null: false
      t.text :description, null: false
      t.integer :position, null: false
      t.string :title, null: false
      t.timestamps
      t.index [ :course_id, :position ], unique: true
      t.index :course_id
    end
    add_foreign_key :sections, :courses

    create_table :lessons, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :article
      t.text :description
      t.integer :duration_in_seconds, null: false
      t.string :lesson_type, null: false
      t.integer :position, null: false
      t.uuid :section_id, null: false
      t.string :title, null: false
      t.timestamps
      t.index [ :section_id, :position ], unique: true
      t.index :section_id
    end
    add_foreign_key :lessons, :sections

    create_table :lesson_progresses, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid :enrollment_id, null: false
      t.uuid :lesson_id, null: false
      t.integer :progress, default: 0, null: false
      t.string :status, default: "not_started", null: false
      t.integer :watched_seconds, default: 0, null: false
      t.timestamps
      t.index [ :enrollment_id, :lesson_id ], unique: true, name: "index_lesson_progresses_on_enrollment_and_lesson"
      t.index :lesson_id
    end
    add_foreign_key :lesson_progresses, :enrollments
    add_foreign_key :lesson_progresses, :lessons

    add_column :enrollments, :last_accessed_lesson_id, :uuid
    add_foreign_key :enrollments, :lessons, column: :last_accessed_lesson_id
  end
end
