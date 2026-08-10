class AddGoalActivity < ActiveRecord::Migration[8.1]
  def change
    create_table :goal_activities, id: :uuid do |t|
      t.references :goal, null: false, foreign_key: true, type: :uuid
      t.references :student, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.references :admin,   type: :uuid, null: false, foreign_key: { to_table: :users }

      t.string :description, null: false
      t.date :date, null: false
      t.integer :progress, null: false



      t.timestamps
    end
  end
end
