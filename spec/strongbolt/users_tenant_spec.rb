require "spec_helper"

describe Strongbolt::UsersTenant do

  before(:all) do
    define_model "TenantModel" do
      self.table_name = "models"

      tenant
    end
    define_model "Model" do
      self.table_name = "models"
    end
  end
  
  let(:user)          { User.create! }
  let(:tenant)        { TenantModel.create! }

  let(:users_tenant)  { Strongbolt::UsersTenantModel.new user: user, tenant_model: tenant }

  subject { users_tenant }

  it { is_expected.to belong_to :user }
  it { is_expected.to belong_to :tenant_model }

  it { is_expected.to be_valid }
  it { is_expected.to validate_presence_of :user }
  it { is_expected.to validate_presence_of :tenant_model }

  it "should ensure tenant is a Tenant" do
    expect do
      users_tenant = Strongbolt::UsersTenantModel.new user: user, tenant_model: Model.create!
    end.to raise_error ActiveRecord::AssociationTypeMismatch
  end

end