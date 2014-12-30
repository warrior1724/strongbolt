module Strongbolt
  module Controllers
    #
    # Creates the url helpers without the 'strongbolt_' prefix,
    # that both Strongbolt views and the app views can use
    #
    module UrlHelpers
      URLS = %w{roles role new_role edit_role user_groups user_group new_user_group edit_user_group
        user_group_users user_group_user role_capabilities role_capability}

      URLS.each do |url|
        [:path, :url].each do |path_or_url|
          class_eval <<-URL_HELPERS
            def #{url}_#{path_or_url}
              send(:main_app).send("strongbolt_#{url}_#{path_or_url}")
            end
          URL_HELPERS
        end
      end
    end
  end
end