require "spec_helper"

describe Strongbolt::Configuration do
  

  #
  # User class
  #
  describe "user class" do
    
    it "should default to User" do
      expect(Strongbolt::Configuration.user_class).to eq "User"
    end

    context "when setting it" do
      before { Strongbolt::Configuration.user_class = "Account" }
      after { Strongbolt::Configuration.user_class = "User" }

      it "should give it" do
        expect(Strongbolt::Configuration.user_class).to eq "Account"
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
    after { Strongbolt::Configuration.tenants = [] }

    it "should tenant the models" do
      Strongbolt::Configuration.tenants = "Model", OtherModel, Model
      expect(Strongbolt::Configuration.tenants).to eq [Model, OtherModel]
    end

  end

  #
  # Configuring Capability Models
  #
  describe "models=" do
    before do
      Strongbolt::Configuration.models = "OtherModel", "Model"
    end
    after do
      Capability.models = nil
    end

    it "should set Capability::Models" do
      expect(Capability.models).to eq ["Model", "OtherModel", "Strongbolt::Capability", "Strongbolt::Role", "Strongbolt::UserGroup", "Strongbolt::UsersTenant"]
    end

    context "when adding other models" do
      before do
        Strongbolt::Configuration.models = "Model", "LastModel"
      end

      it "should merge with current models" do
        expect(Capability.models).to eq ["LastModel", "Model", "OtherModel", "Strongbolt::Capability", "Strongbolt::Role", "Strongbolt::UserGroup", "Strongbolt::UsersTenant"]
      end
    end

    context "when adding 1 model" do
      before do
        Strongbolt::Configuration.models = "BottomModel"
      end

      it "should merge with current models" do
        expect(Capability.models).to eq ["BottomModel", "Model", "OtherModel", "Strongbolt::Capability", "Strongbolt::Role", "Strongbolt::UserGroup", "Strongbolt::UsersTenant"]
      end
    end
  end #/models=



  #
  # Setting default permissions
  #
  describe "default_capabilities=" do
    
    before do
      Strongbolt::Configuration.default_capabilities = [
        {:model => "User", :actions => :all},
        {:model => "Model", :actions => "find"}
      ]
    end
    after do
      Strongbolt::Configuration.default_capabilities = []
    end

    it "should return 5 Capabilities" do
      expect(Strongbolt::Configuration.default_capabilities.size).to eq 5
    end

    it "should return Capability" do
      Strongbolt::Configuration.default_capabilities.each do |c|
        expect(c).to be_a Capability
      end
    end

  end

end