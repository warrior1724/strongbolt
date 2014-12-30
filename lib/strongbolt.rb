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
  raise StandardError, "You cannot use Strongbolt with ActiveRecord versions 4.1.0 and 4.1.1. Please upgrade to 4.1.2+"
end

#
# Includes every module needed (including Grant)
#
ActiveRecord::Base.send :include, Strongbolt::Bolted

#
# Default behavior, when method current_user defined on controller
#
if defined?(ActionController) and defined?(ActionController::Base)

  ActionController::Base.send :include, Strongbolt::BoltedController

end

#
# Setup controllers, views, helpers and session related configuration
#
require 'strongbolt/engine' if defined?(Rails::Engine)


#
# Main module
#
module Strongbolt
  extend Forwardable

  def self.table_name_prefix
    'strongbolt_'
  end
  
  # Delegates to the configuration the access denied
  def_delegators Configuration, :access_denied, :logger, :tenants, :user_class
  module_function :access_denied, :logger, :tenants, :user_class

  # Delegates switching thread behavior
  def_delegators Grant::Status, :switch_to_multithread,
    :switch_to_monothread
  module_function :switch_to_multithread, :switch_to_monothread

  #
  # Tje parent controller to all strongbolt controllers
  #
  mattr_accessor :parent_controller
  @@parent_controller = "ApplicationController"

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
      if user.class.name != Strongbolt::Configuration.user_class
        raise Strongbolt::WrongUserClass
      end

      # If the user class doesn't have included the module yet
      unless user.class.included_modules.include? Strongbolt::UserAbilities
        user.class.send :include, Strongbolt::UserAbilities
      end
    end

    # Then we call the original grant method
    Grant::User.current_user = user unless Grant::User.current_user == user
  end

  #
  # Setting up Strongbolt
  #
  def self.setup &block
    # Fix to prevent an issue where the DB could not be created from scratch
    return if $0 =~ /rake$/
    
    # Configuration by user
    block.call Configuration

    # Include the User::Abilities
    begin
      user_class = Configuration.user_class
      user_class = user_class.constantize if user_class.is_a? String
      user_class.send(:include, Strongbolt::UserAbilities) unless user_class.included_modules.include?(Strongbolt::UserAbilities)
    rescue NameError
      logger.warn "User class #{Configuration.user_class} wasn't found"
    end
  rescue ActiveRecord::StatementInvalid => e
    logger.fatal "Error while setting up Strongbolt:\n\n#{e}"
  end

  #
  # Perform the block without grant
  #
  def self.without_authorization &block
    Grant::Status.without_grant &block
  end

  #
  # Perform the block with grant
  #
  def self.with_authorization &block
    Grant::Status.with_grant &block
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

  # Include helpers in the given scope to AC and AV.
  def self.include_helpers(scope)
    ActiveSupport.on_load(:action_controller) do
      include scope::UrlHelpers
      include Rails.application.routes.url_helpers if defined?(Rails.application.routes.url_helpers)
    end

    ActiveSupport.on_load(:action_view) do
      include scope::UrlHelpers
      include Rails.application.routes.url_helpers if defined?(Rails.application.routes.url_helpers)
    end
  end

  # Not to use directly
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
      Strongbolt.without_authorization do
        send aliased_name, *args, &block
      end
    end
  end
end
