require "spec_helper"

module Strongbolt

  describe Bolted do

    #
    # Bolted?
    #
    describe "bolted?" do

      context 'when grant is disabled' do
        it "should return false" do
          without_grant do
            expect(Model.bolted?).to eq false
          end
        end
      end # End Grant disabled

      context "when no user but enabled" do
        before do
          expect(Grant::User).to receive(:current_user)
        end

        it "should return false" do
          expect(Model.bolted?).to eq false
        end
      end

      context "when using rails is on console" do
        before do
          rails = class_double 'Rails'#, :console => true
        end

        it "should return false" do
          expect(Model.bolted?).to eq false
        end
      end

    end

    it "should let create a model" do
      expect do
        Model.create! name: "Cool"
      end.not_to raise_error
    end

  end

  #
  # Owned?
  #
  describe 'owned?' do

    context "when model is User" do
      let(:user) { User.create! }

      it "should be true" do
        expect(User).to be_owned
      end

      it "should return the user id" do
        expect(user.strongbolt_owner_id).to eq user.id
      end

      it "should have the right owner attribute" do
        expect(User.owner_attribute).to eq :id
      end
    end

    context 'when model is ownable' do

      before do
        define_model "OwnedModel" do
          self.table_name = "models"

          belongs_to :user
        end
      end

      let(:model) { OwnedModel.create! user: User.create! }

      it "should be true" do
        expect(OwnedModel).to be_owned
      end

      it "should return the model user id" do
        expect(model.strongbolt_owner_id).to eq model.user_id
      end

      it "should have the right owner attribute" do
        expect(OwnedModel.owner_attribute).to eq :user_id
      end

    end

    context 'when model isnt ownable' do

      it "should be true" do
        expect(UnownedModel).not_to be_owned
      end

      it "should raise error" do
        expect do
          UnownedModel.new.strongbolt_owner_id
        end.to raise_error ModelNotOwned
      end

    end

  end

  #
  # Name for authorization
  #
  describe 'name_for_authorization' do
    it "should default to model name" do
      expect(Model.send(:name_for_authorization)).to eq "Model"
    end
  end

  #
  # Authorize as
  #
  describe 'authorize_as' do

    before { Model.authorize_as "ParentModel" }
    after { Model.authorize_as nil }

    it "should have changed name for authorization" do
      expect(Model.send(:name_for_authorization)).to eq "ParentModel"
    end

  end

end
