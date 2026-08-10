class GoalComments < ActiveRecord::Migration[8.1]
  def change
    create_table :goal_comments, id: :uuid do | t|
      t.references :goal, null: false, foreign_key: true, type: :uuid
      t.references :admin, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.string :comment, null: false


      t.timestamps
    end
  end
end
