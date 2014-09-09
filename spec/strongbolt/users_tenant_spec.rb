require "spec_helper"

describe StrongBolt::UsersTenant do

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

  let(:users_tenant)  { StrongBolt::UsersTenant.new user: user, tenant: tenant }

  subject { users_tenant }

  it { is_expected.to belong_to :user }
  it { is_expected.to belong_to :tenant }

  it { is_expected.to be_valid }
  it { is_expected.to validate_presence_of :user }
  it { is_expected.to validate_presence_of :tenant }

  it "should ensure tenant is a Tenant" do
    users_tenant = StrongBolt::UsersTenant.new user: user, tenant: Model.create!
    expect(users_tenant).not_to be_valid
  end

end