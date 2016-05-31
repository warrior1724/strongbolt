require "strongbolt/generators/migration"

module Strongbolt
  module Generators
    #
    # Creates a migration to fix a has many through with users tenants problem
    #
    class FixUniqueGroupMembersGenerator < Rails::Generators::Base
      include Strongbolt::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      def copy_fix
        copy_migration "fix_unique_group_members", "fix_unique_group_members"
      end

    end
  end
end
