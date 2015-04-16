class CreateStrongboltTables < ActiveRecord::Migration
  def change
    create_table :strongbolt_capabilities, :force => true do |t|
      t.string   :name
      t.string   :description
      t.string   :model
      t.string   :action
      t.string   :attr
      t.boolean  :require_ownership, :default => false, :null => false
      t.boolean  :require_tenant_access, :default => true, :null => false

      t.timestamps
    end

    create_table :strongbolt_roles, :force => true do |t|
      t.string   :name
      t.integer  :parent_id
      t.integer  :lft
      t.integer  :rgt
      t.string   :description

      t.timestamps
    end

    create_table :strongbolt_user_groups, :force => true do |t|
      t.string :name
      t.text :description

      t.timestamps
    end

    create_table :strongbolt_user_groups_users, :id => false, :force => true do |t|
      t.integer :user_group_id
      t.integer :user_id
    end

    create_table :strongbolt_roles_user_groups, :id => false, :force => true do |t|
      t.integer :user_group_id
      t.integer :role_id
    end

    create_table :strongbolt_capabilities_roles, :id => false, :force => true do |t|
      t.integer  :role_id
      t.integer  :capability_id
    end

    create_table :strongbolt_users_tenants, :force => true do |t|
      t.integer  :user_id
      t.integer  :tenant_id
      t.string   :tenant_type
    end
  end
end

