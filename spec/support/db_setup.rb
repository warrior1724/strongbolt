require 'active_support/core_ext'
require 'active_record'

tmpdir = File.join(File.dirname(__FILE__), '..', '..', 'tmp')
FileUtils.mkdir(tmpdir) unless File.exist?(tmpdir)
test_db = File.join(tmpdir, 'test.db')

connection_spec = {
  :adapter => 'sqlite3',
  :database => test_db
}

# Delete any existing instance of the test database
FileUtils.rm test_db, :force => true

# Create a new test database
ActiveRecord::Base.establish_connection(connection_spec)

# Models used during the tests

class TestsMigrations < ActiveRecord::Migration
  def change
    create_table :users, :force => true do |t|
      t.string :username

      t.timestamps
    end

    create_table :models, :force => true do |t|
      t.string :name
      t.string :value
      t.integer :user_id
      t.integer :parent_id

      t.timestamps
    end

    create_table :child_models, :force => true do |t|
      t.integer :model_id
      t.string  :model_type
      t.integer :parent_id

      t.timestamps
    end

    create_table :unowned_models, :force => true do |t|
      t.string :name
      t.string :value

      t.timestamps
    end

    create_table :model_models, :force => true do |t|
      t.integer :parent_id
      t.integer :child_id
    end

    create_table :strongbolt_capabilities, :force => true do |t|
      t.string   :name
      t.string   :description
      t.string   :model
      t.string   :action
      t.string   :attr
      t.boolean  :require_ownership, :default => false, :null => false
      t.boolean  :require_tenant_access, :default => true, :null => false

      t.timestamps
    end

    create_table :strongbolt_roles, :force => true do |t|
      t.string   :name
      t.integer  :parent_id
      t.integer  :lft
      t.integer  :rgt
      t.string   :description

      t.timestamps
    end

    create_table :strongbolt_user_groups, :force => true do |t|
      t.string :name
      t.text :description

      t.timestamps
    end

    create_table :strongbolt_user_groups_users, :id => false, :force => true do |t|
      t.integer :user_group_id
      t.integer :user_id
    end

    create_table :strongbolt_roles_user_groups, :id => false, :force => true do |t|
      t.integer :user_group_id
      t.integer :role_id
    end

    create_table :strongbolt_capabilities_roles, :id => false, :force => true do |t|
      t.integer  :role_id
      t.integer  :capability_id
    end

    create_table :strongbolt_users_tenants, :id => false, :force => true do |t|
      t.integer  :user_id
      t.integer  :tenant_id
      t.string   :tenant_type
    end
  end
end

class User < ActiveRecord::Base; end
class Model < ActiveRecord::Base; end
class UnownedModel < ActiveRecord::Base; end



