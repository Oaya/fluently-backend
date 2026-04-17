class CreateEnrollments < ActiveRecord::Migration[8.1]
  def change
    create_table :enrollments, id: :uuid do |t|
      t.references :tenant, type: :uuid, null: false, foreign_key: true
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :course, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end

    add_index :enrollments, [ :tenant_id, :user_id, :course_id ], unique: true
  end
end
