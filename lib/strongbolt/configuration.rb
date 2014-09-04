module StrongBolt

  module Configuration

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