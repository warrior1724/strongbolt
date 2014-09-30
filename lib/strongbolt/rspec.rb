#
# Setups Rspec related stuff to handle correctly StrongBolt
#
require 'strongbolt'

StrongBolt.switch_to_multithread

if defined?(Rspec)
  # We load the class that overrides user behavior,
  # more convenient for tests
  require 'strongbolt/rspec/user'
  
  RSpec.configure do |config|
    config.around(:each) do |example|
      StrongBolt.without_authorization &example
    end
  end
end