class FixUniqueGroupMembers < ActiveRecord::Migration[4.2]
  def change
    add_index :strongbolt_user_groups_users, %i[user_group_id user_id], unique: true, name: :index_strongbolt_user_groups_users_unique
  end
end
