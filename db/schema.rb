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

ActiveRecord::Schema[8.1].define(version: 2026_04_26_204048) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bookable_services", force: :cascade do |t|
    t.integer "business_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "duration_minutes", null: false
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id", "is_active"], name: "index_bookable_services_on_business_id_and_is_active"
    t.index ["business_id"], name: "index_bookable_services_on_business_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.integer "bookable_service_id", null: false
    t.integer "business_id", null: false
    t.datetime "created_at", null: false
    t.string "customer_email"
    t.string "customer_name", null: false
    t.string "customer_phone", null: false
    t.datetime "end_at", null: false
    t.text "notes"
    t.datetime "start_at", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["bookable_service_id", "start_at"], name: "index_bookings_on_bookable_service_id_and_start_at"
    t.index ["bookable_service_id"], name: "index_bookings_on_bookable_service_id"
    t.index ["business_id", "start_at"], name: "index_bookings_on_business_id_and_start_at"
    t.index ["business_id", "status"], name: "index_bookings_on_business_id_and_status"
    t.index ["business_id"], name: "index_bookings_on_business_id"
    t.index ["customer_phone"], name: "index_bookings_on_customer_phone"
  end

  create_table "businesses", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "email"
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["is_active"], name: "index_businesses_on_is_active"
    t.index ["user_id"], name: "index_businesses_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "full_name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "working_hours", force: :cascade do |t|
    t.integer "business_id", null: false
    t.datetime "created_at", null: false
    t.integer "day_of_week", null: false
    t.time "end_time"
    t.boolean "is_closed", default: false, null: false
    t.time "start_time"
    t.datetime "updated_at", null: false
    t.index ["business_id", "day_of_week"], name: "index_working_hours_on_business_id_and_day_of_week", unique: true
    t.index ["business_id"], name: "index_working_hours_on_business_id"
  end

  add_foreign_key "bookable_services", "businesses"
  add_foreign_key "bookings", "bookable_services"
  add_foreign_key "bookings", "businesses"
  add_foreign_key "businesses", "users"
  add_foreign_key "working_hours", "businesses"
end
