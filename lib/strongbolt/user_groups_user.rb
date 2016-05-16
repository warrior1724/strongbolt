module Strongbolt
  class UserGroupsUser < Base
    authorize_as "Strongbolt::UserGroup"

    belongs_to :user_group,
      :class_name => "Strongbolt::UserGroup",
      :inverse_of => :user_groups_users

    belongs_to :user,
      :class_name => Configuration.user_class,
      :foreign_key => :user_id,
      :inverse_of => :user_groups_users

    validates_presence_of :user_group, :user
  end
end
