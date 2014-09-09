require 'rails/generators/base'

module StrongBolt
  module Generators
    class InstallGenerator < Rails::Generators::Base
      
      include Rails::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      def copy_migrations
        copy_migration "migration", "create_strongbolt_tables"
      end

      private

      def copy_migration(source, target)
        if self.class.migration_exists?("db/migrate", "#{target}")
          say_status "skipped", "Migration #{target}.rb already exists"
        else
          migration_template "migrations/#{source}.rb", "db/migrate/#{target}.rb"
        end
      end

    end
  end
end