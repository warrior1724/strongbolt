module Strongbolt
  class CapabilitiesRole < Base
    authorize_as "Strongbolt::Role"

    belongs_to :role,
      :class_name => "Strongbolt::Role",
      :inverse_of => :capabilities_roles
    
    belongs_to :capability,
      :class_name => "Strongbolt::Capability",
      :inverse_of => :capabilities_roles

    validates_presence_of :role, :capability
  end
end