module Strongbolt
  class UsersTenant < ActiveRecord::Base
    self.inheritance_column = :tenant_type

    validates :user, presence: true
  end
end

UsersTenant = Strongbolt::UsersTenant unless defined? UsersTenant