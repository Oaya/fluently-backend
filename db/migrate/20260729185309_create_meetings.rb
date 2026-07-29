class CreateMeetings < ActiveRecord::Migration[8.1]
  def change
    create_table :meetings, id: :uuid do |t|
      t.references :lesson, null: false, foreign_key: true, type: :uuid, index: false
      t.string :room_name
      t.string :room_url
      t.datetime :expires_at

      t.timestamps
    end

    add_index :meetings, :lesson_id, unique: true
  end
end
