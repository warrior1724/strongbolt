require 'rails/generators/active_record'

module Strongbolt
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      def copy_migrations
        copy_migration "migration", "create_strongbolt_tables"
      end

      def copy_initializer
        # Laods all the application models
        Rails.application.eager_load!
        # Copy the file
        copy_file "strongbolt.rb", "config/initializers/strongbolt.rb"
        # Fill in the list of models
        gsub_file "config/initializers/strongbolt.rb", "#{MODELS}",
          ActiveRecord::Base.descendants.map { |m| "'#{m.name}'"  }.join(", ")
      end

      #
      # Need to add this here... Don't know why it's not in a module
      #
      def self.next_migration_number(dirname)
        next_migration_number = current_migration_number(dirname) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
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