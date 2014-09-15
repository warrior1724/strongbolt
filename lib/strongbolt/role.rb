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

    private

    def should_not_have_user_groups
      if user_groups.size > 0
        raise ActiveRecord::DeleteRestrictionError.new :user_groups
      end
    end
  end
end

Role = StrongBolt::Role unless defined? Role