require "active_record"
require "awesome_nested_set"

require "grant/grantable"
require 'grant/user'

require "strongbolt/version"
require "strongbolt/configuration"
require "strongbolt/tenantable"
require "strongbolt/bolted"
require "strongbolt/user_abilities"
require "strongbolt/capability"
require "strongbolt/role"
require "strongbolt/user_group"
require "strongbolt/users_tenant"

#
# Includes every module needed (including Grant)
#
ActiveRecord::Base.send :include, StrongBolt::Bolted

#
# Default behavior, when method current_user defined on controller
#
if defined?(ActionController) and defined?(ActionController::Base)

  ActionController::Base.class_eval do
    before_filter do |c|
      StrongBolt.logger.debut "Before Filter of StrongBolt - Current User method defined? #{c.respond_to? :current_user}"
      # To be accessible in the model when not granted
      $request = request
      StrongBolt.current_user = c.send(:current_user) if c.respond_to?(:current_user)
    end
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
  # Current User
  #
  def self.current_user
    Grant::User.current_user
  end

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
    Grant::User.current_user = user
  end

  #
  # Setting up StrongBolt
  #
  def self.setup &block
    # Configuration by user
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

  StrongBoltError = Class.new StandardError
  WrongUserClass = Class.new StrongBoltError
  ModelNotOwned = Class.new StrongBoltError
  TenantError = Class.new StrongBoltError
  InverseAssociationNotConfigured = Class.new TenantError
  DirectAssociationNotConfigured = Class.new TenantError

  private

  def self.tenants= tenants
    @@tenants = tenants
  end
end
