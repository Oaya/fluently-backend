class RenameSessionsToLessons < ActiveRecord::Migration[8.0]
  def change
    rename_table :sessions, :lessons
  end
end
