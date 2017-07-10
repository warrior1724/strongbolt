require 'rails/generators/active_record'

module Strongbolt
  module Generators
    module Migration
      def self.included(receiver)
        receiver.send :include, Rails::Generators::Migration
        receiver.send :include, InstanceMethods
        receiver.extend         ClassMethods
      end

      module ClassMethods
        #
        # Need to add this here... Don't know why it's not in a Rails module
        #
        def next_migration_number(dirname)
          next_migration_number = current_migration_number(dirname) + 1
          ActiveRecord::Migration.next_migration_number(next_migration_number)
        end
      end

      module InstanceMethods
        def copy_migration(source, target)
          if self.class.migration_exists?('db/migrate', target.to_s)
            say_status 'skipped', "Migration #{target}.rb already exists"
          else
            migration_template "#{source}.rb", "db/migrate/#{target}.rb"
          end
        end
      end
    end
  end
end
