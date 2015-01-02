class StrongboltController < Strongbolt.parent_controller.constantize
  include Rails.application.routes.url_helpers if defined?(Rails.application.routes.url_helpers)
end