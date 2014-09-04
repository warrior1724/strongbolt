require 'grant'

require "strongbolt/version"
require "strongbolt/configuration"
require "strongbolt/bolted"

ActiveRecord::Base.send :include, StrongBolt::Bolted

module StrongBolt
  #
  # Setting up StrongBolt
  #
  def self.setup &block
    block.call Configuration
  end

  #
  # Called when the access was denied
  #
  def self.access_denied user, instance, action, request_path
    if Configuration.access_denied_block.present?
      Configuration.access_denied_block.call user, instance, action, request_path
    end
  end
end
