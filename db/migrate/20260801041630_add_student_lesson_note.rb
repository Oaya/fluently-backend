class AddStudentLessonNote < ActiveRecord::Migration[8.1]
  def change
    add_column :lessons, :student_note, :string
  end
end
