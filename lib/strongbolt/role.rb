module Strongbolt
  class Role < ActiveRecord::Base

    acts_as_nested_set

    validates :name, presence: true

    has_and_belongs_to_many :user_groups,
      class_name: "Strongbolt::UserGroup"
    has_many :users, through: :user_groups

    has_and_belongs_to_many :capabilities,
      class_name: "Strongbolt::Capability"

    before_destroy :should_not_have_user_groups
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

    def should_not_have_user_groups
      if user_groups.count > 0
        raise ActiveRecord::DeleteRestrictionError.new :user_groups
      end
    end

    def should_not_have_children
      if children.count > 0
        raise ActiveRecord::DeleteRestrictionError.new :children
      end
    end
  end
end

Role = Strongbolt::Role unless defined? Role