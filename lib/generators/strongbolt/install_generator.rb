require 'strongbolt/generators/migration'

module Strongbolt
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Strongbolt::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      def copy_migrations
        copy_migration 'migration', 'create_strongbolt_tables'
      end

      def copy_initializer
        # Laods all the application models
        Rails.application.eager_load!
        # Copy the file
        copy_file 'strongbolt.rb', 'config/initializers/strongbolt.rb'
        # Fill in the list of models of the application
        gsub_file 'config/initializers/strongbolt.rb', '%MODELS%',
                  ActiveRecord::Base.descendants
                                    .reject { |m| m.name =~ /^Strongbolt::/ }
                                    .map    { |m| "'#{m.name}'" }
                                    .join(', ')
      end
    end
  end
end
