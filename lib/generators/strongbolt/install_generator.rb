require 'rails/generators/active_record'

module Strongbolt
  module Generators
    class InstallGenerator < ActiveRecord::Generators::Base

      source_root File.expand_path('../templates', __FILE__)

      def copy_migrations
        copy_migration "migration", "create_strongbolt_tables"
      end

      private

      def copy_migration(source, target)
        if self.class.migration_exists?("db/migrate", "#{target}")
          say_status "skipped", "Migration #{target}.rb already exists"
        else
          migration_template "#{source}.rb", "db/migrate/#{target}.rb"
        end
      end

    end
  end
end