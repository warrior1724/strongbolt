module Strongbolt
  class UsersTenant < ActiveRecord::Base
    belongs_to :user, class_name: Configuration.user_class
    belongs_to :tenant, polymorphic: true

    validates :user, :tenant, presence: true
    validate :tenant_model_is_a_tenant

    private

    def tenant_model_is_a_tenant
      if tenant.present? && !tenant.class.tenant?
        errors.add :tenant, "should be configured as a Tenant. Class #{tenant.class} is not."
      end
    end
  end
end

UsersTenant = Strongbolt::UsersTenant unless defined? UsersTenant