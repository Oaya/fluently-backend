class AddRoomNameToLessons < ActiveRecord::Migration[8.1]
  def change
    add_column :lessons, :room_name, :string
    add_column :lessons, :meeting_feedback, :string
    add_column :lessons, :meeting_duration_in_seconds, :integer
  end
end
