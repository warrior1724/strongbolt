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
    #
    # When creating stuff in before :all, avoid leaks
    #
    config.before(:all) do
      StrongBolt.current_user = nil
    end

    config.around(:each) do |example|
      StrongBolt.without_authorization &example
      # Clear all the User authorizations that could have been defined
      User.clear_authorizations
      # Removes the user from current_user to avoid leaks
      StrongBolt.current_user = nil
    end
  end
end