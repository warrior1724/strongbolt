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

ActiveRecord::Schema.define(version: 20160531110509) do

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

  add_index "strongbolt_capabilities_roles", ["capability_id"], name: "index_strongbolt_capabilities_roles_on_capability_id"
  add_index "strongbolt_capabilities_roles", ["role_id"], name: "index_strongbolt_capabilities_roles_on_role_id"

  create_table "strongbolt_roles", force: true do |t|
    t.string   "name"
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "strongbolt_roles", ["lft"], name: "index_strongbolt_roles_on_lft"
  add_index "strongbolt_roles", ["parent_id"], name: "index_strongbolt_roles_on_parent_id"
  add_index "strongbolt_roles", ["rgt"], name: "index_strongbolt_roles_on_rgt"

  create_table "strongbolt_roles_user_groups", id: false, force: true do |t|
    t.integer "user_group_id"
    t.integer "role_id"
  end

  add_index "strongbolt_roles_user_groups", ["role_id"], name: "index_strongbolt_roles_user_groups_on_role_id"
  add_index "strongbolt_roles_user_groups", ["user_group_id"], name: "index_strongbolt_roles_user_groups_on_user_group_id"

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

  add_index "strongbolt_user_groups_users", ["user_group_id", "user_id"], name: "index_strongbolt_user_groups_users_unique", unique: true
  add_index "strongbolt_user_groups_users", ["user_group_id"], name: "index_strongbolt_user_groups_users_on_user_group_id"
  add_index "strongbolt_user_groups_users", ["user_id"], name: "index_strongbolt_user_groups_users_on_user_id"

  create_table "strongbolt_users_tenants", force: true do |t|
    t.integer "user_id"
    t.integer "tenant_id"
    t.string  "type"
  end

  add_index "strongbolt_users_tenants", ["tenant_id", "type"], name: "index_strongbolt_users_tenants_on_tenant_id_and_type"
  add_index "strongbolt_users_tenants", ["tenant_id"], name: "index_strongbolt_users_tenants_on_tenant_id"
  add_index "strongbolt_users_tenants", ["type"], name: "index_strongbolt_users_tenants_on_type"
  add_index "strongbolt_users_tenants", ["user_id"], name: "index_strongbolt_users_tenants_on_user_id"

end
