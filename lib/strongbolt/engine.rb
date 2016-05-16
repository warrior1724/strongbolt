require "strongbolt/rails/routes"

require "strongbolt/helpers"
require "strongbolt/controllers/url_helpers"

module Strongbolt
  class Engine < ::Rails::Engine

    initializer 'strongbolt.assets.precompile' do |app|
      %w(javascripts).each do |sub|
        app.config.assets.paths << root.join('app', 'assets', sub).to_s
      end
    end

    initializer "strongbolt.helpers" do
      ActionView::Base.send :include, Strongbolt::Helpers
    end

    #
    # Session Store should be accessible anytime
    #
    initializer "strongbolt.session" do
      if defined? ActiveRecord::SessionStore::Session
        ActiveRecord::SessionStore::Session.grant(:find, :create, :update, :destroy) { true }
      end
    end

    #
    # Avoids authorization checking in the middleware
    #
    initializer "strongbolt.devise_integration" do
      if defined?(Warden) && defined?(Warden::SessionSerializer)
        Warden::SessionSerializer.perform_without_authorization :store, :fetch, :delete
      end
    end

    #
    # Initialize our custom url helpers
    #
    initializer "strongbolt.url_helpers" do
      Strongbolt.include_helpers Strongbolt::Controllers
    end
  end
end
