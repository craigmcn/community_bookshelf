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

ActiveRecord::Schema[8.1].define(version: 2026_08_16_175557) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "books", force: :cascade do |t|
    t.bigint "added_by_id", null: false
    t.string "author"
    t.string "cover_url"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "isbn"
    t.integer "page_count"
    t.date "published_on"
    t.bigint "series_id"
    t.integer "series_position"
    t.string "subjects", default: [], null: false, array: true
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["added_by_id"], name: "index_books_on_added_by_id"
    t.index ["series_id"], name: "index_books_on_series_id"
  end

  create_table "readings", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.integer "rating"
    t.text "review"
    t.integer "status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["book_id"], name: "index_readings_on_book_id"
    t.index ["user_id"], name: "index_readings_on_user_id"
  end

  create_table "role_assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["role_id"], name: "index_role_assignments_on_role_id"
    t.index ["user_id", "role_id"], name: "index_role_assignments_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_role_assignments_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "series", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_series_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "confirmation_token", limit: 128
    t.datetime "created_at", null: false
    t.string "email"
    t.string "encrypted_password", limit: 128
    t.string "remember_token", limit: 128
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["remember_token"], name: "index_users_on_remember_token", unique: true
  end

  add_foreign_key "books", "series"
  add_foreign_key "books", "users", column: "added_by_id"
  add_foreign_key "readings", "books"
  add_foreign_key "readings", "users"
  add_foreign_key "role_assignments", "roles"
  add_foreign_key "role_assignments", "users"
end
