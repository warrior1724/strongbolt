module Strongbolt
  #
  # This is a STI model that will have subclasses making links
  # from users to tenants (if one or more tenants are defined)
  #
  class UsersTenant < Base
    # Required validation for every subclass
    validates :user, presence: true
  end
end

UsersTenant = Strongbolt::UsersTenant unless defined? UsersTenant