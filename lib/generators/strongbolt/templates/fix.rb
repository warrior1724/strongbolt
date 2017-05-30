class FixStrongboltUsersTenantsId < ActiveRecord::Migration[4.2]
  def change
    add_column :strongbolt_users_tenants, :id, :primary_key
  end
end
