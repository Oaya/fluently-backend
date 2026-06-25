class HomeWork < ActiveRecord::Migration[8.1]
  def change
    create_table :homeworks, id: :uuid do |t|
      t.references :student, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.references :admin,   type: :uuid, null: false, foreign_key: { to_table: :users }

      t.string :title, null: false
      t.date :due_date, null: false
      t.string :status, null: false, default: "pending"
      t.date :submitted_at
      t.date :reviewed_at
      t.string :language
      t.string :level
      t.boolean :ai_generated

      t.timestamps
    end
  end
end
