module Strongbolt
  class RolesUserGroup < ActiveRecord::Base
    belongs_to :user_group,
      :class_name => "Strongbolt::UserGroup",
      :inverse_of => :roles_user_groups
    
    belongs_to :role,
      :class_name => "Strongbolt::Role",
      :inverse_of => :roles_user_groups

    validates_presence_of :user_group, :role
  end
end