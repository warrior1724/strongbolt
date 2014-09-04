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
      t.column :username, :string
    end

    create_table :models, :force => true do |t|
      t.column :name, :string
      t.column :value, :string
    end
  end
end

class User < ActiveRecord::Base; end
class Model < ActiveRecord::Base; end