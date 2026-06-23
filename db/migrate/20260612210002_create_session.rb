class CreateSession < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions, id: :uuid do |t|
      t.references :student, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.references :admin,   type: :uuid, null: false, foreign_key: { to_table: :users }


      t.date :scheduled_at, null: false
      t.integer :duration_in_minutes
      t.string :status, null: false, default: "scheduled"
      t.string :topic
      t.string :note
      t.string :payment_status, default: "unpaid"
      t.timestamps
    end
  end
end
