module Strongbolt
  class UserGroup < Base
    has_many :user_groups_users,
             class_name: 'Strongbolt::UserGroupsUser',
             dependent: :restrict_with_exception,
             inverse_of: :user_group
    has_many :users, through: :user_groups_users

    has_many :roles_user_groups,
             class_name: 'Strongbolt::RolesUserGroup',
             dependent: :delete_all,
             inverse_of: :user_group

    has_many :roles, through: :roles_user_groups

    has_many :capabilities, through: :roles

    validates_presence_of :name
  end
end
