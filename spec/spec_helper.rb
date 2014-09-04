require 'rspec'
require 'strongbolt'

# Needed because not required by default without controllers
require 'grant/user'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|

  config.include GrantHelpers

  #
  # We setup and teardown the database for our tests
  #
  config.before(:suite) do
    TestsMigrations.new.migrate :up
  end

  config.after(:suite) do
    TestsMigrations.new.migrate :down
  end

end