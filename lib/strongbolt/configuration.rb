module StrongBolt

  module Configuration

    #
    # A placeholder class for logger when not defined
    # Just print what's given
    #
    class DefaultLogger
      def method_missing method_name, text
        puts "[#{method_name}] #{text}"
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
    # Allows to configure what happens when the access is denied,
    # or call the block that has been given
    #
    def self.access_denied *args, &block
      if block.present?
        @@access_denied_block = block
      else
        @@access_denied_block.call *args
      end
    end

  end

end