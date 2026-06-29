class HwSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :homework_submissions, id: :uuid do |t|
      t.references :student, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.references :homework, type: :uuid, null: false, foreign_key: true

      t.string :answer_text
      t.string :status, null: false, default: "draft"
      t.date :submitted_at
      t.date :reviewed_at
      t.timestamps
    end

    add_index :homework_submissions, [ :student_id, :homework_id ], unique: true
  end
end
