require "active_record"
require "awesome_nested_set"

require "grant/grantable"
require "grant/status"
require 'grant/user'

require "strongbolt/version"
require "strongbolt/errors"
require "strongbolt/configuration"
require "strongbolt/tenantable"
require "strongbolt/bolted"
require "strongbolt/bolted_controller"
require "strongbolt/user_abilities"
require "strongbolt/capability"
require "strongbolt/role"
require "strongbolt/user_group"
require "strongbolt/users_tenant"

#
# Raise an error if version of AR not compatible (4.1.0 and 4.1.1)
#
ar_version = ActiveRecord.version.version
if ar_version >= "4.1.0" && ar_version <= "4.1.1"
  raise StandardError, "You cannot use StrongBolt with ActiveRecord versions 4.1.0 and 4.1.1. Please upgrade to at least 4.1.2."
end

#
# Includes every module needed (including Grant)
#
ActiveRecord::Base.send :include, StrongBolt::Bolted

#
# Default behavior, when method current_user defined on controller
#
if defined?(ActionController) and defined?(ActionController::Base)

  ActionController::Base.send :include, StrongBolt::BoltedController

end

require 'strongbolt/railtie' if defined?(Rails::Railtie)


#
# Main module
#
module StrongBolt
  extend Forwardable

  def self.table_name_prefix
    'strongbolt_'
  end
  
  # Delegates to the configuration the access denied
  def_delegators Configuration, :access_denied, :logger, :tenants
  module_function :access_denied, :logger, :tenants

  #
  # Current User
  #
  def self.current_user
    Grant::User.current_user
  end

  # We keep an hash so we don't have each time to test
  # if the module is included in the list
  def self.current_user= user
    # If user is an instance of something and different from what we have
    if user.present?
      # Raise error if wrong user class
      if user.class.name != StrongBolt::Configuration.user_class
        raise StrongBolt::WrongUserClass
      end

      # If the user class doesn't have included the module yet
      unless user.class.included_modules.include? StrongBolt::UserAbilities
        user.class.send :include, StrongBolt::UserAbilities
      end
    end

    # Then we call the original grant method
    Grant::User.current_user = user unless Grant::User.current_user == user
  end

  #
  # Setting up StrongBolt
  #
  def self.setup &block
    # Configuration by user
    block.call Configuration

    # Include the User::Abilities
    begin
      user_class = Configuration.user_class
      user_class = user_class.constantize if user_class.is_a? String
      user_class.send(:include, StrongBolt::UserAbilities) unless user_class.included_modules.include?(StrongBolt::UserAbilities)
    rescue NameError
      logger.warn "User class #{Configuration.user_class} wasn't found"
    end
  end

  #
  # Perform the block without grant
  #
  def self.without_authorization &block
    Grant::Status.without_grant &block
  end

  #
  # Disable authorization checking
  #
  def self.disable_authorization
    Grant::Status.disable_grant
  end

  def self.enable_authorization
    Grant::Status.enable_grant
  end

  def self.enabled?
    Grant::Status.grant_enabled?
  end
  def self.disabled?
    ! enabled?
  end

  private

  def self.tenants= tenants
    @@tenants = tenants
  end
end

#
# We add a method to any object to quickly tell which method
# should not have any authorization check perform 
#
class Object
  def self.perform_without_authorization *method_names
    method_names.each {|name| setup_without_authorization name}
  end

  private

  def self.setup_without_authorization method_name
    aliased_name = "_with_autorization_#{method_name}"
    alias_method aliased_name, method_name
    define_method method_name do |*args, &block|
      StrongBolt.without_authorization do
        send aliased_name, *args, &block
      end
    end
  end
end
