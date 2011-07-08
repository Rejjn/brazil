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

ActiveRecord::Schema.define(:version => 20110708140716) do

  create_table "activities", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.string   "schema"
    t.string   "state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "app_id"
    t.string   "db_type"
    t.string   "dev_schema"
    t.string   "dev_user"
    t.string   "dev_password"
    t.string   "db_instance_id"
    t.string   "base_version"
  end

  create_table "apps", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "vc_path"
  end

  create_table "changes", :force => true do |t|
    t.string   "developer"
    t.integer  "activity_id"
    t.text     "sql"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state"
  end

  create_table "db_instances", :force => true do |t|
    t.string   "host"
    t.integer  "port"
    t.string   "db_env"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "db_alias"
    t.string   "db_type"
    t.boolean  "wipeable_schemas"
  end

  create_table "versions", :force => true do |t|
    t.string   "schema"
    t.integer  "state"
    t.integer  "activity_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "update_sql"
    t.text     "rollback_sql"
    t.text     "preparation"
    t.string   "schema_version"
    t.boolean  "create_schema_version"
  end

end
