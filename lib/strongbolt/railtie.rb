require "strongbolt/helpers"

module StrongBolt
  class Railtie < Rails::Railtie
    initializer "strongbolt.helpers" do
      ActionView::Base.send :include, StrongBolt::Helpers
    end
  end
end