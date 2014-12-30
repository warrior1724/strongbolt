module Strongbolt
  class SecurityController < ::StrongboltController
    self.model_for_authorization = "Role"

    def index
    end
  end
end