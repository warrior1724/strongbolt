module StrongBolt
  class UserGroup < ActiveRecord::Base

    has_and_belongs_to_many :users, class_name: Configuration.user_class,
      :join_table => :strongbolt_user_groups_users
    
    has_and_belongs_to_many :roles, class_name: "StrongBolt::Role"
    has_many :capabilities, through: :roles

    validates_presence_of :name

    before_destroy :should_not_have_users

    private

    def should_not_have_users
      if users.size > 0
        raise ActiveRecord::DeleteRestrictionError.new :users
      end
    end

  end
end

UserGroup = StrongBolt::UserGroup unless defined? UserGroup