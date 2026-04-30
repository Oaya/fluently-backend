class Lesson < ActiveRecord::Migration[8.1]
  def change
    change_column :lessons, :duration_in_seconds, :integer, null: false
  end
end
