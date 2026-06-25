class DropEnrollments < ActiveRecord::Migration[8.1]
  def change
    drop_table :enrollments, id: :uuid
  end
end
