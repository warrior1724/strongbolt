require "spec_helper"

describe Strongbolt::UserAbilities do

  before(:all) do
    define_model "TenantA" do
      self.table_name = "tenant_a"

      has_many :model_with_tenant
    end
    define_model "TenantB" do
      self.table_name = "tenant_b"

      has_many :model_with_tenant
    end

    define_model "ModelWithTenant" do
      self.table_name = "model_with_tenants"

      belongs_to :tenant_a
      belongs_to :tenant_b
    end

    Strongbolt::Configuration.add_tenant TenantA
    Strongbolt::Configuration.add_tenant TenantB
  end
  after(:all) do
    undefine_model TenantA
    undefine_model TenantB
    Strongbolt::Configuration.tenants = []
  end


  #
  # Creates some fixtures for the tests here
  #
  def create_fixtures
    @user1 = User.create!
    @user2 = User.create!
    @user3 = User.create!

    @tenant_a = TenantA.create!
    @tenant_b = TenantB.create!
    @user1.add_tenant @tenant_a
    @user1.add_tenant @tenant_b
    @user2.add_tenant @tenant_a
    @user3.add_tenant @tenant_b

    @tenanted_model1 = ModelWithTenant.create! tenant_a: @tenant_a, tenant_b: @tenant_b
    @tenanted_model2 = ModelWithTenant.create! tenant_a: @tenant_a
    @tenanted_model3 = ModelWithTenant.create! tenant_b: @tenant_b

    @group = Strongbolt::UserGroup.create! name: "Normal"
    @group.users << @user1
    @group.users << @user2
    @group.users << @user3

    @role = @group.roles.create! name: "Normal"
    @role.capabilities.create! model: "User", action: "update", require_ownership: true
    @role.capabilities.create! model: "ModelWithTenant", action: "find", require_tenant_access: true
  end



  #
  # Has access to tenants?
  #
  describe "has_access_to_tenants?" do
    before { create_fixtures }

    it "should be true when model is tenant" do
      expect(@user1.send :has_access_to_tenants?, @tenant_a).to eq true
      expect(@user1.send :has_access_to_tenants?, @tenant_b).to eq true
      expect(@user2.send :has_access_to_tenants?, @tenant_a).to eq true
      expect(@user2.send :has_access_to_tenants?, @tenant_b).to eq false
      expect(@user3.send :has_access_to_tenants?, @tenant_a).to eq false
      expect(@user3.send :has_access_to_tenants?, @tenant_b).to eq true
    end

    it "should be true when model is first child" do
      expect(@user1.send :has_access_to_tenants?, @tenanted_model1).to eq true
      expect(@user1.send :has_access_to_tenants?, @tenanted_model2).to eq true
      expect(@user1.send :has_access_to_tenants?, @tenanted_model3).to eq true
      expect(@user2.send :has_access_to_tenants?, @tenanted_model1).to eq true
      expect(@user2.send :has_access_to_tenants?, @tenanted_model2).to eq true
      expect(@user2.send :has_access_to_tenants?, @tenanted_model3).to eq false
      expect(@user3.send :has_access_to_tenants?, @tenanted_model1).to eq true
      expect(@user3.send :has_access_to_tenants?, @tenanted_model2).to eq false
      expect(@user3.send :has_access_to_tenants?, @tenanted_model3).to eq true
    end
  end

end
