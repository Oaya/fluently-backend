class AddLessonNote < ActiveRecord::Migration[8.1]
  def change
    add_column :lessons, :teacher_note, :string
    add_column :lessons, :note_shared, :boolean
    rename_column :lessons, :note, :meeting_note
  end
end
