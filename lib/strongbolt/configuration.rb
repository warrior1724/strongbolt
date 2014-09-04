module StrongBolt

  module Configuration

    #
    # Allows to configure what happens when the access is denied
    #
    def self.access_denied &block
      @@access_denied_block = block
    end

    #
    # Returns the block to call when access is denied
    #
    def self.access_denied_block
      @@access_denied_block
    end

  end

end