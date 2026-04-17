class AddStatusToEnrollments < ActiveRecord::Migration[8.1]
  def change
    add_column :enrollments, :status, :string, default: "enrolled", null: false
  end
end
