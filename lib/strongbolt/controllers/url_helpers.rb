require 'active_support/inflector'

module Strongbolt
  module Controllers
    #
    # Creates the url helpers without the 'strongbolt_' prefix,
    # that both Strongbolt views and the app views can use
    #
    module UrlHelpers
      URLS = %w{role capability user_group user_group_user}

      def self.create_url_helper url, scope=nil
        [:path, :url].each do |path_or_url|
          class_eval <<-URL_HELPERS
            def #{scope.present? ? "#{scope}_" : ''}#{url}_#{path_or_url} *args
              send(:main_app).send("#{scope.present? ? "#{scope}_" : ''}strongbolt_#{url}_#{path_or_url}", *args)
            end
          URL_HELPERS
        end
      end

      URLS.each do |url|
        create_url_helper url
        create_url_helper url.pluralize
        [:new, :edit].each { |scope| create_url_helper url, scope }
      end
    end
  end
end