module StrongBolt
  class Role < ActiveRecord::Base

    acts_as_nested_set

    validates :name, presence: true

    has_and_belongs_to_many :user_groups,
      class_name: "StrongBolt::UserGroup"
    has_many :users, through: :user_groups

    has_and_belongs_to_many :capabilities,
      class_name: "StrongBolt::Capability"

  end
end

Role = StrongBolt::Role unless defined? Role