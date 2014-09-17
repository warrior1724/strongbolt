require "strongbolt/helpers"

module StrongBolt
  class Railtie < Rails::Railtie
    initializer "strongbolt.helpers" do
      ActionView::Base.send :include, StrongBolt::Helpers
    end

    initializer "strongbolt.session" do
      #
      # Session Store should be accessible anytime
      #
      if defined? ActiveRecord::SessionStore::Session
        ActiveRecord::SessionStore::Session.grant(:find, :create, :update, :destroy) { true }
      end
    end

    initializer "strongbolt.devise_integration" do
      if defined? DeviseController
        Warden::SessionSerializer.perform_without_authorization :store, :fetch, :delete
      end
    end
  end
end