module StrongBolt
  class Role < ActiveRecord::Base

    acts_as_nested_set

    validates :name, presence: true

    has_and_belongs_to_many :user_groups,
      class_name: "StrongBolt::UserGroup"
    has_many :users, through: :user_groups

    has_and_belongs_to_many :capabilities,
      class_name: "StrongBolt::Capability"

    before_destroy :should_not_have_user_groups
    before_destroy :should_not_have_children

    # We SHOULD NOT destroy descendants in our case
    skip_callback :destroy, :before, :destroy_descendants

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

Role = StrongBolt::Role unless defined? Role