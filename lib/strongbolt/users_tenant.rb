module Strongbolt
  class UsersTenant < ActiveRecord::Base
    belongs_to :user, class_name: Configuration.user_class,
      :inverse_of => :users_tenants
    # belongs_to :tenant, polymorphic: true

    self.inheritance_column = :tenant_type

    validates :user, presence: true
    # validate :tenant_model_is_a_tenant

    # See below for explanation
    # before_validation :set_tenant_type

    private

    def tenant_model_is_a_tenant
      if tenant.present? && !tenant.class.tenant?
        errors.add :tenant, "should be configured as a Tenant. Class #{tenant.class} is not."
      end
    end

    #
    # This sets the tenant_type to be the actual class of the tenant
    #
    # This is to avoid cases of STI where a subclass is the Tenant and not the base class
    #
    def set_tenant_type
      self.tenant_type = tenant.class.name
    end
  end
end

UsersTenant = Strongbolt::UsersTenant unless defined? UsersTenant