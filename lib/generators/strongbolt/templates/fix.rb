class FixStrongboltUsersTenantsId < ActiveRecord::Migration
  def change
    add_column :strongbolt_users_tenants, :id, :primary_key
  end
end