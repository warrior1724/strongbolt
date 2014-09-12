module StrongBolt
  module Helpers
    delegate :can?, :cannot?, to: :current_user
  end
end