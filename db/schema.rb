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

ActiveRecord::Schema[8.1].define(version: 2026_06_29_032932) do
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

  create_table "homework_submissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "answer_text"
    t.datetime "created_at", null: false
    t.uuid "homework_id", null: false
    t.date "reviewed_at"
    t.string "status", default: "draft", null: false
    t.uuid "student_id", null: false
    t.date "submitted_at"
    t.datetime "updated_at", null: false
    t.index ["homework_id"], name: "index_homework_submissions_on_homework_id"
    t.index ["student_id", "homework_id"], name: "index_homework_submissions_on_student_id_and_homework_id", unique: true
    t.index ["student_id"], name: "index_homework_submissions_on_student_id"
  end

  create_table "homeworks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "admin_id", null: false
    t.boolean "ai_generated"
    t.datetime "created_at", null: false
    t.date "due_date", null: false
    t.string "instructions"
    t.string "language"
    t.string "level"
    t.uuid "student_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_homeworks_on_admin_id"
    t.index ["student_id"], name: "index_homeworks_on_student_id"
  end

  create_table "lessons", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "admin_id", null: false
    t.datetime "created_at", null: false
    t.integer "duration_in_minutes"
    t.string "language", default: "", null: false
    t.string "note"
    t.string "payment_status", default: "unpaid"
    t.datetime "scheduled_at", null: false
    t.string "status", default: "scheduled", null: false
    t.uuid "student_id", null: false
    t.string "topic"
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_lessons_on_admin_id"
    t.index ["student_id"], name: "index_lessons_on_student_id"
  end

  create_table "plans", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "features"
    t.string "name", null: false
    t.integer "price", null: false
    t.string "stripe_price_id"
    t.datetime "updated_at", null: false
  end

  create_table "submission_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "homework_submission_id", null: false
    t.string "sub"
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["homework_submission_id"], name: "index_submission_attachments_on_homework_submission_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "admin_id"
    t.boolean "cancel_at_period_end"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.string "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name", null: false
    t.datetime "invitation_accepted_at"
    t.datetime "invitation_created_at"
    t.integer "invitation_limit"
    t.datetime "invitation_sent_at"
    t.string "invitation_token"
    t.integer "invitations_count", default: 0
    t.uuid "invited_by_id"
    t.string "invited_by_type"
    t.string "last_name", null: false
    t.string "learning_languages", default: [], array: true
    t.uuid "plan_id"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "student", null: false
    t.string "status", default: "active", null: false
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.string "subscription_status"
    t.string "timezone"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
    t.index ["plan_id"], name: "index_users_on_plan_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "homework_submissions", "homeworks"
  add_foreign_key "homework_submissions", "users", column: "student_id"
  add_foreign_key "homeworks", "users", column: "admin_id"
  add_foreign_key "homeworks", "users", column: "student_id"
  add_foreign_key "lessons", "users", column: "admin_id"
  add_foreign_key "lessons", "users", column: "student_id"
  add_foreign_key "submission_attachments", "homework_submissions"
  add_foreign_key "users", "plans"
end
