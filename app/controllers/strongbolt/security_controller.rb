module StrongBolt
  class SecurityController < ::StrongBoltController
    self.model_for_authorization = "Role"

    def index
    end
  end
end