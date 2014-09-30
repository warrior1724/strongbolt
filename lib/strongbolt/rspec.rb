#
# Setups Rspec related stuff to handle correctly StrongBolt
#
require 'strongbolt'

StrongBolt.switch_to_multithread

if defined?(RSpec)
  # We load the class that overrides user behavior,
  # more convenient for tests
  require 'strongbolt/rspec/user'

  RSpec.configure do |config|
    config.around(:each) do |example|
      StrongBolt.without_authorization &example
      # Clear all the User authorizations that could have been defined
      User.clear_authorizations
    end
  end
end