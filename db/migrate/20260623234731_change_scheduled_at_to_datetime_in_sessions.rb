class ChangeScheduledAtToDatetimeInSessions < ActiveRecord::Migration[8.1]
  def up
    change_column :sessions, :scheduled_at, :datetime, null: false, using: "scheduled_at::timestamp"
  end

  def down
    change_column :sessions, :scheduled_at, :date, null: false, using: "scheduled_at::date"
  end
end
