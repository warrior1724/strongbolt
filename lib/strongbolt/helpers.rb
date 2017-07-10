module Strongbolt
  module Helpers
    def can?(*args, &block)
      # Block can be used when testing an instance
      Strongbolt.without_authorization do
        args.insert 1, yield if block.present?

        return current_user.can?(*args)
      end
    end

    def cannot?(*args, &block)
      !can?(*args, &block)
    end
  end
end
