require 'fixtures/application'
require 'fixtures/controllers'

require 'strongbolt'
require 'shoulda/matchers'

require 'rspec/rails'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|

  config.include Helpers
  config.include TransactionalSpecs

  #
  # We setup and teardown the database for our tests
  #
  config.before(:suite) do
    TestsMigrations.new.migrate :up
    User.send :include, Strongbolt::UserAbilities
  end

  config.after(:suite) do
    TestsMigrations.new.migrate :down
  end

end