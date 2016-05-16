module Strongbolt
  class SecurityController < ::StrongboltController
    self.model_for_authorization = "Strongbolt::Role"

    def index
    end
  end
end
