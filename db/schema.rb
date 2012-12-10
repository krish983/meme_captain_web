# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121209081928) do

  create_table "gend_images", :force => true do |t|
    t.string   "id_hash"
    t.integer  "src_image_id"
    t.integer  "user_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "src_images", :force => true do |t|
    t.string   "id_hash"
    t.string   "url"
    t.integer  "width"
    t.integer  "height"
    t.integer  "size"
    t.string   "content_type"
    t.binary   "image"
    t.integer  "src_thumb_id"
    t.integer  "user_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "src_thumbs", :force => true do |t|
    t.integer  "src_image_id"
    t.integer  "width"
    t.integer  "height"
    t.integer  "size"
    t.binary   "image"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.string   "format"
  end

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "password_digest"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

end
