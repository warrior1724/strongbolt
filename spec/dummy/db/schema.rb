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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150106225152) do

  create_table "strongbolt_capabilities", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.string   "model"
    t.string   "action"
    t.string   "attr"
    t.boolean  "require_ownership",     default: false, null: false
    t.boolean  "require_tenant_access", default: true,  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "strongbolt_capabilities_roles", id: false, force: true do |t|
    t.integer "role_id"
    t.integer "capability_id"
  end

  create_table "strongbolt_roles", force: true do |t|
    t.string   "name"
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "strongbolt_roles_user_groups", id: false, force: true do |t|
    t.integer "user_group_id"
    t.integer "role_id"
  end

  create_table "strongbolt_user_groups", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "strongbolt_user_groups_users", id: false, force: true do |t|
    t.integer "user_group_id"
    t.integer "user_id"
  end

  create_table "strongbolt_users_tenants", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "tenant_id"
    t.string  "tenant_type"
  end

end
