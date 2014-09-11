module StrongBolt

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
    @@user_class = 'User'
    def self.user_class= name
      @@user_class = name
    end

    def self.user_class() @@user_class; end

    #
    # Sets the logger used by StrongBolt
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

  end

end