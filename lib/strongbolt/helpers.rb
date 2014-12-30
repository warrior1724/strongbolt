module Strongbolt
  module Helpers
    def can? *args, &block
      # Block can be used when testing an instance
      Strongbolt.without_authorization do
        if block.present?
          args.insert 1, block.call
        end

        return current_user.can? *args
      end
    end

    def cannot? *args, &block
      ! can? *args, &block
    end
  end
end