module Strongbolt
  class Role < Base

    acts_as_nested_set

    validates :name, presence: true

    has_many :roles_user_groups,
      :class_name => "Strongbolt::RolesUserGroup",
      :dependent => :restrict_with_exception,
      :inverse_of => :role
    has_many :user_groups, :through => :roles_user_groups

    has_many :users, through: :user_groups

    has_many :capabilities_roles,
      :class_name => "Strongbolt::CapabilitiesRole",
      :dependent => :delete_all,
      :inverse_of => :role
    has_many :capabilities, :through => :capabilities_roles

    before_destroy :should_not_have_children

    # We SHOULD NOT destroy descendants in our case
    skip_callback :destroy, :before, :destroy_descendants

    #
    # Returns inherited capabilities
    #
    def inherited_capabilities
      Strongbolt::Capability.joins(:roles)
        .where("strongbolt_roles.lft < :lft AND strongbolt_roles.rgt > :rgt", lft: lft, rgt: rgt)
        .distinct
    end

    private

    def should_not_have_children
      if children.count > 0
        raise ActiveRecord::DeleteRestrictionError.new :children
      end
    end
  end
end

Role = Strongbolt::Role unless defined? Role
