require "grant"
require "grant/user"

require "awesome_nested_set"

require "strongbolt/version"
require "strongbolt/configuration"
require "strongbolt/tenantable"
require "strongbolt/bolted"
require "strongbolt/user_abilities"
require "strongbolt/capability"
require "strongbolt/role"
require "strongbolt/user_group"

ActiveRecord::Base.send :include, StrongBolt::Bolted
ActiveRecord::Base.send :include, StrongBolt::Tenantable

#
# Updates Grant current_user method to raise an error if the user
# doesn't have the UserAbilities module included
#

# Alias the method
Grant::User.singleton_class.send(:alias_method, :_current_user=, :current_user=)

# Implements the new behavior
Grant::User.class_eval do
  # We keep an hash so we don't have each time to test
  # if the module is included in the list
  def self.current_user= user
    # Raise error if wrong user class
    if user.class.name != StrongBolt::Configuration.user_class
      raise StrongBolt::WrongUserClass
    end

    # If the user class doesn't have included the module yet
    unless user.class.included_modules.include? StrongBolt::UserAbilities
      user.class.send :include, StrongBolt::UserAbilities
    end

    # Then we call the original grant method
    self._current_user = user
  end
end



#
# Main module
#
module StrongBolt
  extend Forwardable

  def self.table_name_prefix
    'strongbolt_'
  end
  
  # Delegates to the configuration the access denied
  def_delegators Configuration, :access_denied, :logger
  module_function :access_denied, :logger

  #
  # Setting up StrongBolt
  #
  def self.setup &block
    block.call Configuration
  end

  #
  # Tenant models
  #
  def self.add_tenant model
    @@tenants ||= []
    @@tenants |= [model]
  end
  def self.tenants() @@tenants ||= []; end

  class StrongBoltError < StandardError; end
  class WrongUserClass < StrongBoltError; end
  class AssociationNotConfigured < StrongBoltError; end
end
