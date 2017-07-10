class CreateStrongboltTables < ActiveRecord::Migration[4.2]
  def change
    create_table :strongbolt_capabilities, force: true do |t|
      t.string   :name
      t.string   :description
      t.string   :model
      t.string   :action
      t.string   :attr
      t.boolean  :require_ownership, default: false, null: false
      t.boolean  :require_tenant_access, default: true, null: false

      t.timestamps
    end

    create_table :strongbolt_roles, force: true do |t|
      t.string   :name
      t.integer  :parent_id
      t.integer  :lft
      t.integer  :rgt
      t.string   :description

      t.timestamps
    end

    create_table :strongbolt_user_groups, force: true do |t|
      t.string :name
      t.text :description

      t.timestamps
    end

    create_table :strongbolt_user_groups_users, force: true do |t|
      t.integer :user_group_id
      t.integer :user_id
    end

    create_table :strongbolt_roles_user_groups, force: true do |t|
      t.integer :user_group_id
      t.integer :role_id
    end

    create_table :strongbolt_capabilities_roles, force: true do |t|
      t.integer  :role_id
      t.integer  :capability_id
    end

    create_table :strongbolt_users_tenants, force: true do |t|
      t.integer  :user_id
      t.integer  :tenant_id
      t.string   :type
    end

    # Indexes
    add_index :strongbolt_roles, :parent_id
    add_index :strongbolt_roles, :lft
    add_index :strongbolt_roles, :rgt

    add_index :strongbolt_user_groups_users, :user_group_id
    add_index :strongbolt_user_groups_users, :user_id

    add_index :strongbolt_roles_user_groups, :user_group_id
    add_index :strongbolt_roles_user_groups, :role_id

    add_index :strongbolt_capabilities_roles, :role_id
    add_index :strongbolt_capabilities_roles, :capability_id

    add_index :strongbolt_users_tenants, :user_id
    add_index :strongbolt_users_tenants, :tenant_id
    add_index :strongbolt_users_tenants, :type
    add_index :strongbolt_users_tenants, %i[tenant_id type]

    add_index :strongbolt_user_groups_users, %i[user_group_id user_id], unique: true, name: :index_strongbolt_user_groups_users_unique
  end
end
