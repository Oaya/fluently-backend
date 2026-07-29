class CreateGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :goals, id: :uuid do |t|
      t.references :student, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.references :admin,   type: :uuid, null: false, foreign_key: { to_table: :users }

      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "not_started"
      t.integer :progress
      t.date :target_date, null: false
      t.date :achieved_at

      t.timestamps
    end
  end
end
