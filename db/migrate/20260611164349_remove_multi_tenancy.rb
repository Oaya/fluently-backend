class RemoveMultiTenancy < ActiveRecord::Migration[8.1]
  def change
    # Remove foreign keys referencing tenants
    remove_foreign_key "courses", "tenants"
    remove_foreign_key "enrollments", "tenants"
    remove_foreign_key "lesson_progresses", "tenants"
    remove_foreign_key "lessons", "tenants"
    remove_foreign_key "memberships", "tenants"
    remove_foreign_key "sections", "tenants"
    remove_foreign_key "tenants", "plans"
    remove_foreign_key "tenants", "users", column: "billing_owner_id"
    remove_foreign_key "users", "tenants"

    # Remove tenant_id indexes before dropping columns
    remove_index "courses", name: "index_courses_on_tenant_id"
    remove_index "enrollments", name: "index_enrollments_on_tenant_id"
    remove_index "enrollments", name: "index_enrollments_on_tenant_id_and_user_id_and_course_id"
    remove_index "lesson_progresses", name: "index_lesson_progresses_on_tenant_id"
    remove_index "lessons", name: "index_lessons_on_tenant_id"
    remove_index "memberships", name: "index_memberships_on_tenant_id"
    remove_index "sections", name: "index_sections_on_tenant_id"
    remove_index "users", name: "index_users_on_tenant_id"

    # Replace the enrollment uniqueness index (was tenant+user+course, now just user+course)
    add_index "enrollments", [ "user_id", "course_id" ], unique: true,
              name: "index_enrollments_on_user_id_and_course_id"

    # Remove tenant_id columns
    remove_column "courses", "tenant_id", :uuid
    remove_column "enrollments", "tenant_id", :uuid
    remove_column "lesson_progresses", "tenant_id", :uuid
    remove_column "lessons", "tenant_id", :uuid
    remove_column "sections", "tenant_id", :uuid
    remove_column "users", "tenant_id", :uuid

    # Drop the tables that are no longer needed
    drop_table "memberships"
    drop_table "tenants"

    # Add role and subscription columns to users
    add_column :users, :role, :string, null: false, default: "student"
    add_column :users, :plan_id, :uuid
    add_column :users, :stripe_customer_id, :string
    add_column :users, :stripe_subscription_id, :string
    add_column :users, :current_period_end, :datetime
    add_column :users, :cancel_at_period_end, :boolean
    add_column :users, :subscription_status, :string

    add_foreign_key :users, :plans, column: :plan_id

    add_index :users, :role, name: "index_users_on_role"
    add_index :users, :plan_id, name: "index_users_on_plan_id"
  end
end
