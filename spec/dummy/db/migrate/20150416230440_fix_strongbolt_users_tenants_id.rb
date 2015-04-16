class FixStrongboltUsersTenantsId < ActiveRecord::Migration
  def up
    add_column :strongbolt_users_tenants, :id, :primary_key
  end
end