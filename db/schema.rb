# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_30_050053) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "course_instructors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "course_id", null: false
    t.datetime "created_at", null: false
    t.uuid "instructor_id", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "instructor_id"], name: "index_course_instructors_on_course_id_and_instructor_id", unique: true
    t.index ["instructor_id"], name: "index_course_instructors_on_instructor_id"
  end

  create_table "courses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.string "level"
    t.decimal "price", precision: 10, scale: 2
    t.boolean "published", default: false
    t.uuid "tenant_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_courses_on_tenant_id"
  end

  create_table "enrollments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "course_id", null: false
    t.datetime "created_at", null: false
    t.uuid "last_accessed_lesson_id"
    t.integer "overall_progress", default: 0, null: false
    t.string "status", default: "enrolled", null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["course_id"], name: "index_enrollments_on_course_id"
    t.index ["tenant_id", "user_id", "course_id"], name: "index_enrollments_on_tenant_id_and_user_id_and_course_id", unique: true
    t.index ["tenant_id"], name: "index_enrollments_on_tenant_id"
    t.index ["user_id"], name: "index_enrollments_on_user_id"
  end

  create_table "lesson_progresses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "enrollment_id", null: false
    t.uuid "lesson_id", null: false
    t.integer "progress", default: 0, null: false
    t.string "status", default: "not_started", null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["enrollment_id", "lesson_id"], name: "index_lesson_progresses_on_enrollment_and_lesson", unique: true
    t.index ["enrollment_id", "lesson_id"], name: "index_lesson_progresses_on_enrollment_id_and_lesson_id", unique: true
    t.index ["lesson_id"], name: "index_lesson_progresses_on_lesson_id"
    t.index ["tenant_id"], name: "index_lesson_progresses_on_tenant_id"
  end

  create_table "lessons", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "article"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "duration_in_seconds", null: false
    t.string "lesson_type", null: false
    t.integer "position", null: false
    t.uuid "section_id", null: false
    t.uuid "tenant_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["section_id", "position"], name: "index_lessons_on_section_id_and_position", unique: true
    t.index ["section_id"], name: "index_lessons_on_section_id"
    t.index ["tenant_id"], name: "index_lessons_on_tenant_id"
  end

  create_table "memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "role", null: false
    t.uuid "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["tenant_id"], name: "index_memberships_on_tenant_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "plans", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "features"
    t.string "name", null: false
    t.integer "price", null: false
    t.string "stripe_price_id"
    t.datetime "updated_at", null: false
  end

  create_table "sections", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "course_id", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.integer "position", null: false
    t.uuid "tenant_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "position"], name: "index_sections_on_course_id_and_position", unique: true
    t.index ["course_id"], name: "index_sections_on_course_id"
    t.index ["tenant_id"], name: "index_sections_on_tenant_id"
  end

  create_table "tenants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "billing_owner_id"
    t.boolean "cancel_at_period_end"
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.string "name", null: false
    t.uuid "plan_id", null: false
    t.string "status", default: "inactive", null: false
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.datetime "updated_at", null: false
    t.index ["billing_owner_id"], name: "index_tenants_on_billing_owner_id"
    t.index ["plan_id"], name: "index_tenants_on_plan_id"
    t.index ["status"], name: "index_tenants_on_status"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name", null: false
    t.datetime "invitation_accepted_at"
    t.datetime "invitation_created_at"
    t.integer "invitation_limit"
    t.datetime "invitation_sent_at"
    t.string "invitation_token"
    t.integer "invitations_count", default: 0
    t.bigint "invited_by_id"
    t.string "invited_by_type"
    t.string "last_name", null: false
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "status", default: "active", null: false
    t.uuid "tenant_id", null: false
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["tenant_id"], name: "index_users_on_tenant_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "course_instructors", "courses"
  add_foreign_key "course_instructors", "users", column: "instructor_id"
  add_foreign_key "courses", "tenants"
  add_foreign_key "enrollments", "courses"
  add_foreign_key "enrollments", "lessons", column: "last_accessed_lesson_id"
  add_foreign_key "enrollments", "tenants"
  add_foreign_key "enrollments", "users"
  add_foreign_key "lesson_progresses", "enrollments"
  add_foreign_key "lesson_progresses", "lessons"
  add_foreign_key "lesson_progresses", "tenants"
  add_foreign_key "lessons", "sections"
  add_foreign_key "lessons", "tenants"
  add_foreign_key "memberships", "tenants"
  add_foreign_key "memberships", "users"
  add_foreign_key "sections", "courses"
  add_foreign_key "sections", "tenants"
  add_foreign_key "tenants", "plans"
  add_foreign_key "tenants", "users", column: "billing_owner_id"
  add_foreign_key "users", "tenants"
end
