module Strongbolt

  module Configuration

    #
    # A placeholder class for logger when not defined
    # Just print what's given
    #
    class DefaultLogger
      def method_missing method_name, text = nil, &block
        puts "[#{method_name}] #{block.present? ? block.call : text}"
      end
    end

    #
    # Sets the class name of the user if different then default 'User'
    #
    mattr_accessor :user_class
    @@user_class = 'User'

    #
    # Returns the constantize version of user class
    #
    def self.user_class_constant() self.user_class.constantize; end

    #
    # Sets the logger used by Strongbolt
    #
    @@logger = DefaultLogger.new
    def self.logger= logger
      @@logger = logger
    end
    def self.logger() @@logger; end

    #
    # Sets the tenants of the application
    #
    @@tenants = []
    def self.tenants= tenants
      @@tenants = []
      [*tenants].each {|t| add_tenant t}
    end

    #
    # Returns the tenants
    #
    def self.tenants() @@tenants; end

    #
    # Adds a tenant if not in the list
    #
    def self.add_tenant tenant
      unless @@tenants.any? { |m| m.name == tenant.name }
        tenant = tenant.constantize if tenant.is_a? String
        tenant.send :tenant
        @@tenants << tenant
      end
    end


    #
    # Allows to configure what happens when the access is denied,
    # or call the block that has been given
    #
    # The block access denied receives as arguments:
    #   user, instance, action, request_path
    #
    def self.access_denied *args, &block
      if block.present?
        @@access_denied_block = block
      else
        @@access_denied_block.call(*args) if defined?(@@access_denied_block)
      end
    end

    #
    # Allows to set Capability Models list
    #
    def self.models= models
      Strongbolt::Capability.add_models models
    end

    #
    # Controllers to skip controller authorization check ups
    #
    def self.skip_controller_authorization_for *controllers
      ActiveSupport.on_load :action_controller do
        controllers.each do |controller|
          begin
            puts "#{controller.classify}Controller"
            "#{controller.classify}Controller".constantize.send :skip_controller_authorization
          rescue NameError => e
            raise NameError, "Controller #{controller} doesn't correspond to a valid controller name"
          end
        end
      end
    end

  end

end