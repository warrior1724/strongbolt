require "spec_helper"

module StrongBolt
  
  describe Capability do
  
    let(:capability) { Capability.new model: "User", action: "find" }

    subject { capability }

    #
    # Associations
    #
    it { is_expected.to have_and_belong_to_many(:roles).class_name "StrongBolt::Role" }
    it { is_expected.to have_many(:users).through :roles }


    #
    # VALIDATIONS
    #

    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of :model }
    it { is_expected.to validate_presence_of :action }

    it { is_expected.to validate_uniqueness_of(:action).scoped_to :model, :require_ownership, :require_tenant_access }

    it { is_expected.to ensure_inclusion_of(:action).in_array %w{find create update destroy} }

    it "should ensure the model exists" do
      capability.model = "UserFake"
      expect(capability).not_to be_valid
    end

  end

end