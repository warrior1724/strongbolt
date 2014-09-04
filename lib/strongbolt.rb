require 'grant'

require "strongbolt/version"
require "strongbolt/configuration"
require "strongbolt/bolted"

ActiveRecord::Base.send :include, StrongBolt::Bolted

module StrongBolt
  extend Forwardable
  
  # Delegates to the configuration the access denied
  def_delegator Configuration, :access_denied
  module_function :access_denied
  
  #
  # Setting up StrongBolt
  #
  def self.setup &block
    block.call Configuration
  end
end
