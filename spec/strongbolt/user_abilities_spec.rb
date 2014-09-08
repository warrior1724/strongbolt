require "spec_helper"

module StrongBolt

  describe UserAbilities do

    let(:user) { User.create! }

    subject { user }


    it { is_expected.to have_and_belong_to_many :user_groups }
    it { is_expected.to have_many(:roles).through :user_groups }
    it { is_expected.to respond_to(:capabilities) }


    #
    # Creates some fixtures for the tests here
    #
    def create_fixtures
      # Another user
      @other_user = User.create!
      # A owned model, owned
      @owned_model = Model.create! user_id: user.id
      # An model not owned
      @unowned_model = Model.create! user_id: @other_user.id
      # An unownable model
      @model = UnownedModel.create!

      # The user belong to a group
      @group = StrongBolt::UserGroup.create! name: "Normal"
      @group.users << user

      # That has a role
      @guest_role = StrongBolt::Role.create! name: "Guest"
      @parent_role = StrongBolt::Role.create! name: "Basic", parent_id: @guest_role.id
      @other_role = StrongBolt::Role.create! name: "Admin"
      @role = @group.roles.create! name: "Normal", parent_id: @parent_role.id

      # Which has capabilities

      # User can update self
      @parent_role.capabilities.create! model: "User", action: "update", require_ownership: true

      # User can read all owned models
      @parent_role.capabilities.create! model: "Model", action: "find"

      # And create some
      @role.capabilities.create! model: "Model", action: "create", require_ownership: true

      # But can delete only owned models
      @role.capabilities.create! model: "Model", action: "destroy", require_ownership: true

      # User can read any unowned models
      @guest_role.capabilities.create! model: "UnownedModel", action: "find"

      # But can create setting only the attribute name
      @role.capabilities.create! model: "UnownedModel", action: "create", attr: "name"
      
      # Admin can do whatever
      @other_role.capabilities.create! model: "UnownedModel", action: "create"
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
          it "should return true when passing instance" do
            expect(user.can? :create, ::Model.new).to eq true
          end

          it "should return true when passing class" do
            expect(user.can? :create, ::Model).to eq true
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
            expect(user.can? :create, ::UnownedModel, :all).to eq false
          end
        end

        context "when requiring any attribute" do
          it "should return true" do
            expect(user.can? :create, ::UnownedModel, :any).to eq true
          end
        end

      end # Creating a model with restricted attributes

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
        expect(cache.size).to eq 4 * 6
      end

      [
        "updateUserall-any", "updateUserany-any", # "updateUserall-#{User.first.id}", "updateUserany-#{User.first.id}",
        "findModelall-any", "findModelany-any", "findModelall-all", "findModelany-all",
        "createModelall-any", "createModelany-any", "createModelall-owned", "createModelany-owned",
        "destroyModelall-any", "destroyModelany-any", "destroyModelall-owned", "destroyModelany-owned",
        "findUnownedModelall-any", "findUnownedModelany-any", "findUnownedModelall-all", "findUnownedModelany-all",
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

end