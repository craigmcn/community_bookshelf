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

ActiveRecord::Schema[8.1].define(version: 2026_08_22_175935) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
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

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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

  create_table "favorite_genres", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["tag_id"], name: "index_favorite_genres_on_tag_id"
    t.index ["user_id", "tag_id"], name: "index_favorite_genres_on_user_id_and_tag_id", unique: true
    t.index ["user_id"], name: "index_favorite_genres_on_user_id"
  end

  create_table "follows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "followed_id", null: false
    t.bigint "follower_id", null: false
    t.datetime "updated_at", null: false
    t.index ["followed_id"], name: "index_follows_on_followed_id"
    t.index ["follower_id", "followed_id"], name: "index_follows_on_follower_id_and_followed_id", unique: true
    t.index ["follower_id"], name: "index_follows_on_follower_id"
    t.check_constraint "follower_id <> followed_id", name: "follows_no_self_follow"
  end

  create_table "readings", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.date "finished_on"
    t.integer "format"
    t.boolean "is_review_public", default: true, null: false
    t.integer "progress_percent"
    t.integer "rating"
    t.text "review"
    t.date "started_on"
    t.integer "status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["book_id"], name: "index_readings_on_book_id"
    t.index ["user_id"], name: "index_readings_on_user_id"
    t.check_constraint "progress_percent IS NULL OR progress_percent >= 0 AND progress_percent <= 100", name: "readings_progress_percent_range"
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

  create_table "shelf_books", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.bigint "shelf_id", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_shelf_books_on_book_id"
    t.index ["shelf_id", "book_id"], name: "index_shelf_books_on_shelf_id_and_book_id", unique: true
    t.index ["shelf_id"], name: "index_shelf_books_on_shelf_id"
  end

  create_table "shelves", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name"], name: "index_shelves_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_shelves_on_user_id"
  end

  create_table "taggings", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id", "tag_id"], name: "index_taggings_on_book_id_and_tag_id", unique: true
    t.index ["book_id"], name: "index_taggings_on_book_id"
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "category", default: "genre", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_tags_on_category"
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.text "bio"
    t.string "confirmation_token", limit: 128
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "email_confirmation_sent_at"
    t.string "email_confirmation_token"
    t.datetime "email_confirmed_at"
    t.string "encrypted_password", limit: 128
    t.string "name"
    t.string "remember_token", limit: 128
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["email_confirmation_token"], name: "index_users_on_email_confirmation_token", unique: true
    t.index ["remember_token"], name: "index_users_on_remember_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "books", "series"
  add_foreign_key "books", "users", column: "added_by_id"
  add_foreign_key "favorite_genres", "tags"
  add_foreign_key "favorite_genres", "users"
  add_foreign_key "follows", "users", column: "followed_id"
  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "readings", "books"
  add_foreign_key "readings", "users"
  add_foreign_key "role_assignments", "roles"
  add_foreign_key "role_assignments", "users"
  add_foreign_key "shelf_books", "books"
  add_foreign_key "shelf_books", "shelves"
  add_foreign_key "shelves", "users"
  add_foreign_key "taggings", "books"
  add_foreign_key "taggings", "tags"
end
