require "strongbolt/generators/migration"

module Strongbolt
  module Generators
    #
    # Creates a migration to fix a has many through with users tenants problem
    #
    class FixGenerator < Rails::Generators::Base
      include Strongbolt::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      def copy_fix
        unless Strongbolt::UsersTenant.primary_key.nil?
          puts"Strongbolt::UsersTenant already has a primary key, no need to use the fix"
        else
          copy_migration "fix", "fix_strongbolt_users_tenants_id"
        end
      end

    end
  end
end