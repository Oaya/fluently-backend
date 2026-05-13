class RemoveOverallProgressFromEnrollments < ActiveRecord::Migration[8.0]
  def change
    remove_column :enrollments, :overall_progress, :integer, default: 0, null: false
  end
end
