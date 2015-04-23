require "spec_helper"

describe Strongbolt::UserAbilities do

  before(:all) do
    #
    # This is a very basic schema that allows having a model,
    # ChildModel, being tenanted by Model
    #
    define_model "TenantModel" do
      self.table_name = "models"

      has_many :owned_models, foreign_key: :parent_id
      belongs_to :unowned_model, foreign_key: :parent_id
    end

    define_model "OwnedModel" do
      self.table_name = "child_models"

      belongs_to :user, foreign_key: :model_id
      belongs_to :tenant_model, foreign_key: :parent_id

      has_many :child_models, foreign_key: :parent_id

      validates :tenant_model, presence: true
    end

    define_model "ChildModel" do
      self.table_name = "model_models"

      belongs_to :owned_model, foreign_key: :parent_id
    end

    define_model "UnownedModel" do
      self.table_name = "unowned_models"

      has_many :tenant_models, foreign_key: :parent_id
    end

    define_model "OtherModel" do
      self.table_name = "models"

      authorize_as "UnownedModel"
    end

    Strongbolt::Configuration.add_tenant TenantModel
  end
  after(:all) do
    undefine_model TenantModel
    Strongbolt::Configuration.tenants = []
  end

  let(:user) { User.create! }

  subject { user }


  # Doesn't work I don't know why
  # it { is_expected.to have_and_belong_to_many :user_groups }
  it { is_expected.to have_many(:roles).through :user_groups }
  it { is_expected.to respond_to(:capabilities) }
  it { is_expected.to have_many(:tenant_models) }

  it "should let user find itself" do
    expect(user.can? :find, user).to eq true
  end


  #
  # Creates some fixtures for the tests here
  #
  def create_fixtures
    # An unown model linked to a tenant
    @linked_to_tenant = UnownedModel.create!
    @tenant_model = TenantModel.create! unowned_model: @linked_to_tenant
    @other_tenant_model = TenantModel.create!
    # Add to the user
    user.add_tenant @tenant_model
    
    # Another user
    @other_user = User.create!
    # A owned model, owned
    @owned_model = OwnedModel.create! user: user,
      tenant_model: @tenant_model
    # An model not owned
    @unowned_model = OwnedModel.create! user: @other_user,
      tenant_model: @tenant_model
    # Other tenant model
    @unmanaged_model = OwnedModel.create! tenant_model: @other_tenant_model
    # An unownable model
    @model = UnownedModel.create!

    # Child
    @child_model = @owned_model.child_models.create!

    # The user belong to a group
    @group = Strongbolt::UserGroup.create! name: "Normal"
    @group.users << user

    # That has a role
    @guest_role = Strongbolt::Role.create! name: "Guest"
    @parent_role = Strongbolt::Role.create! name: "Basic", parent_id: @guest_role.id
    @other_role = Strongbolt::Role.create! name: "Admin"
    @role = @group.roles.create! name: "Normal", parent_id: @parent_role.id

    # Which has capabilities

    # User can update self
    @parent_role.capabilities.create! model: "User", action: "update", require_ownership: true

    # User can read all owned models
    @parent_role.capabilities.create! model: "OwnedModel", action: "find"

    # And create some
    @role.capabilities.create! model: "OwnedModel", action: "create", require_ownership: true

    # But can delete only owned models
    @role.capabilities.create! model: "OwnedModel", action: "destroy", require_ownership: true

    # User can read any unowned models
    @guest_role.capabilities.create! model: "UnownedModel", action: "find"

    # But can create setting only the attribute name
    @role.capabilities.create! model: "UnownedModel", action: "create", attr: "name",
      :require_tenant_access => false
    
    # Admin can do whatever
    @other_role.capabilities.create! model: "UnownedModel", action: "create"
  end




  #
  # Adding a tenant to the user
  #
  describe "add_tenant" do
    
    context 'when instance is from a tenant' do
      let(:model) { TenantModel.create! }

      it "should create an association" do
        expect do
          user.add_tenant model
        end.to change(Strongbolt::UsersTenant, :count).by 1
      end

      it "should add the tenant to users's list" do
        user.add_tenant model
        expect(user.tenant_models).to include model
      end
    end

    context "when instance is not from a tenant" do
      let(:model) { Model.create! }

      it "should raise an error" do
        expect do
          user.add_tenant model
        end.to raise_error
      end
    end

  end



  #
  # Has access to tenants?
  #
  describe "has_access_to_tenants?" do
    before { create_fixtures }

    context "when same tenant" do
      
      it "should be true when model is tenant" do
        expect(user.has_access_to_tenants? @tenant_model).to eq true
      end

      it "should be true when model is first child" do
        expect(user.has_access_to_tenants? @unowned_model).to eq true
      end

      it "should be true when grand child" do
        expect(user.has_access_to_tenants? @child_model).to eq true
      end

      it "should be true for a user defined association" do
        expect(user.has_access_to_tenants? @linked_to_tenant).to eq true
      end

    end

    context "when different tenant" do
      it "should be false when model is tenant" do
        expect(user.has_access_to_tenants? @other_tenant_model).to eq false
      end

      it "should be false when model is first child" do
        expect(user.has_access_to_tenants? @unmanaged_model).to eq false
      end
    end

    context "when model doesn't have link to tenant" do
      it "should return true" do
        expect(user.has_access_to_tenants? @model).to eq true
      end
    end
  end



  #
  # All Capabilities
  #
  describe 'capabilities' do
    
    before { create_fixtures }

    let(:capabilities) { user.capabilities }

    subject { capabilities }

    it "should have 6 capabilities" do
      expect(capabilities.size).to eq 6
    end

  end


  #
  # CAN?
  #

  describe "can?" do
    
    before { create_fixtures }

    describe "creating an owned model" do
      
      context "when authorized" do
        let(:tenant_model) { TenantModel.create! }

        before { user.tenant_models << tenant_model }

        context "when same tenant" do
          let(:instance) { OwnedModel.new tenant_model: tenant_model }

          it "should return true when passing instance" do
            expect(user.can? :create, instance).to eq true
          end
        end

        context "when not same tenant" do

          let(:instance) { OwnedModel.new tenant_model: TenantModel.create! }

          it "should return false when passing instance" do
            expect(user.can? :create, instance).to eq false
          end
        end

        it "should return true when passing class" do
          expect(user.can? :create, OwnedModel).to eq true
        end
      end

      context "when not authorized" do
        it "should return true when passing instance" do
          expect(user.can? :create, User.new).to eq false
        end

        it "should return true when passing class" do
          expect(user.can? :create, User).to eq false
        end
      end

      context "when default set of permissions" do
        before do
          Strongbolt.setup do |config|
            config.default_capabilities = [
              {:model => "OwnedModel", :require_ownership => true, :actions => :update},
              {:model => "TenantModel", :require_tenant_access => false, :require_ownership => false, :actions => "find"}
            ]
          end
        end
        after do 
          Strongbolt.setup do |config|
            config.default_capabilities = []
          end
        end

        let(:other_user) { User.create! }
        let(:owned_model) { OwnedModel.create! :user => user, :tenant_model => TenantModel.create! }
        let(:unowned_model) { OwnedModel.create! :user => other_user, :tenant_model => TenantModel.create! }

        it "should let the user update an owned model" do
          expect(user.can? :update, owned_model).to eq true
        end

        it "should not let the user update an owned model from another user" do
          expect(user.can? :update, unowned_model).to eq false
        end
      end

    end # Creating an owned model

    describe "updating an owned model" do
      context "when owning model" do
        it "should return true" do
          expect(user.can? :update, user).to eq true
        end
      end

      context "when not owning model" do
        it "should return false" do
          expect(user.can? :update, @other_user).to eq false
        end
      end
    end # Updating an owned model

    describe "creating a model with attribute restriction" do
      
      context "when requiring all attributes" do
        it "should return false" do
          expect(user.can? :create, UnownedModel, :all).to eq false
        end

        it "should return false for other model authorized as it" do
          expect(user.can? :create, OtherModel, :all).to eq false
        end
      end

      context "when requiring any attribute" do
        it "should return true" do
          expect(user.can? :create, UnownedModel, :any).to eq true
        end

        it "should return true for other model authorized as it" do
          expect(user.can? :create, OtherModel, :any).to eq true
        end
      end

    end # Creating a model with restricted attributes

    describe "creating a non tenanted model" do
      let(:instance) { UnownedModel.new }

      context "when user has the right" do
        it "should return true" do
          expect(user.can? :create, instance).to eq true
        end
      end
    end

    describe 'destroying an owned model' do
      context "when owning" do
        it "should be true" do
          expect(user.can? :destroy, @owned_model).to eq true
        end
      end

      context "when not owning" do
        it "should be false" do
          expect(user.can? :destroy, @unowned_model).to eq false
        end
      end
    end

    describe "finding model" do
      context "when same tenant" do
        it "should be true" do
          expect(user.can? :find, @unowned_model).to eq true
        end
      end

      context "when not same tenant" do
        it "should be false" do
          expect(user.can? :find, @unmanaged_model).to eq false
        end
      end
    end

  end # End can?





  #
  # Populate Capabilities Cache
  #

  describe "Populate Capabilities Cache" do
    
    #
    # We create some fixtures for the population of cache to be tested
    #
    before { create_fixtures }

    let(:cache) { user.populate_capabilities_cache }

    subject { cache }

    it "should have the right number of capabilities" do
      expect(cache.size).to eq 4 * 6 + 2
    end

    [
      "updateUserall-any", "updateUserany-any", # "updateUserall-#{User.first.id}", "updateUserany-#{User.first.id}",
      "findOwnedModelall-any", "findOwnedModelany-any", "findOwnedModelall-tenanted", "findOwnedModelany-tenanted",
      "createOwnedModelall-any", "createOwnedModelany-any", "createOwnedModelall-owned", "createOwnedModelany-owned",
      "destroyOwnedModelall-any", "destroyOwnedModelany-any", "destroyOwnedModelall-owned", "destroyOwnedModelany-owned",
      "findUnownedModelall-any", "findUnownedModelany-any", "findUnownedModelall-tenanted", "findUnownedModelany-tenanted",
      "createUnownedModelname-any", "createUnownedModelany-any", "createUnownedModelname-all", "createUnownedModelany-all"
    ].each do |key|
      it "should have set true to #{key}" do
        expect(cache[key]).to eq true
      end
    end

  end






  #
  # OWNS?
  #
  describe "owns?" do
    
    #
    # Another user
    #
    context "when testing against a user" do

      context 'when other user' do
      
        let(:other_user) { User.create! }

        it "should not own it" do
          expect(user.owns? other_user).to eq false
        end

      end

      context "when same user" do
        it "should own it" do
          expect(user.owns? user).to eq true
        end
      end

    end # End owning user


    #
    # Another object
    #
    context "when testing against another model having user_id" do
      
      context "when owning it" do
        let(:model) { Model.create! user_id: user.id }

        it "should own it" do
          expect(user.owns? model).to eq true
        end
      end
      
      context "when not owning it" do
        let(:model) { Model.create! user_id: 0 }

        it "should own it" do
          expect(user.owns? model).to eq false
        end
      end

    end # End testing against model having user id

  end


  #
  # Another object unowned
  #
  context "when testing against a model not having user id" do
    
    let(:model) { UnownedModel.create! }

    it "should not own it" do
      expect(user.owns? model).to eq false
    end

  end


  #
  # Wrong arguments
  #
  context "when given something else than an object" do
    it "should raise error" do
      expect do
        user.owns? Model
      end.to raise_error ArgumentError
    end
  end

end