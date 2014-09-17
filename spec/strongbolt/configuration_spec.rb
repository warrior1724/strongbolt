require "spec_helper"

describe StrongBolt::Configuration do
  

  #
  # User class
  #
  describe "user class" do
    
    it "should default to User" do
      expect(StrongBolt::Configuration.user_class).to eq "User"
    end

    context "when setting it" do
      before { StrongBolt::Configuration.user_class = "Account" }
      after { StrongBolt::Configuration.user_class = "User" }

      it "should give it" do
        expect(StrongBolt::Configuration.user_class).to eq "Account"
      end
    end

  end



  #
  # Setting up tenants
  #
  describe 'tenants=' do
    
    before do
      define_model "Model" do
        self.table_name = "models"
      end

      define_model "OtherModel" do
        self.table_name = "models"
      end

      expect(Model).to receive(:send).with :tenant
      expect(OtherModel).to receive(:send).with :tenant
    end
    after { StrongBolt::Configuration.tenants = [] }

    it "should tenant the models" do
      StrongBolt::Configuration.tenants = "Model", OtherModel, Model
      expect(StrongBolt::Configuration.tenants).to eq [Model, OtherModel]
    end

  end

  #
  # Configuring Capability Models
  #
  describe "models=" do
    before do
      StrongBolt::Configuration.models = "OtherModel", "Model"
    end
    after do
      Capability.models = nil
    end

    it "should set Capability::Models" do
      expect(Capability.models).to eq ["Model", "OtherModel", "StrongBolt::Capability", "StrongBolt::Role", "StrongBolt::UserGroup", "StrongBolt::UsersTenant"]
    end

    context "when adding other models" do
      before do
        StrongBolt::Configuration.models = "Model", "LastModel"
      end

      it "should merge with current models" do
        expect(Capability.models).to eq ["LastModel", "Model", "OtherModel", "StrongBolt::Capability", "StrongBolt::Role", "StrongBolt::UserGroup", "StrongBolt::UsersTenant"]
      end
    end

    context "when adding 1 model" do
      before do
        StrongBolt::Configuration.models = "BottomModel"
      end

      it "should merge with current models" do
        expect(Capability.models).to eq ["BottomModel", "Model", "OtherModel", "StrongBolt::Capability", "StrongBolt::Role", "StrongBolt::UserGroup", "StrongBolt::UsersTenant"]
      end
    end
  end

end