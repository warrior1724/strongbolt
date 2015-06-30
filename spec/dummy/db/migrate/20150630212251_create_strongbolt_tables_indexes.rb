class CreateStrongboltTablesIndexes < ActiveRecord::Migration
  def change
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
    add_index :strongbolt_users_tenants, [:tenant_id, :type]
  end
end