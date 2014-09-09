module StrongBolt
  module Generators
    class InstallGenerator < Rails::Generators::Base
      
      include Rails::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      def copy_migrations
        migration_template "migration.rb", "db/migrate/create_strongbolt_tables.rb"
      end

    end
  end
end