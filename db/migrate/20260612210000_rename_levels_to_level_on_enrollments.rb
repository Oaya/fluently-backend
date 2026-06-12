class RenameLevelsToLevelOnEnrollments < ActiveRecord::Migration[8.1]
  def change
    rename_column :enrollments, :levels, :level
  end
end
