require "spec_helper"

module StrongBolt

  describe UserGroup do
    
    let(:user_group) { UserGroup.new name: "PCCC" }

    subject { user_group }

    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of :name }

    it { is_expected.to have_and_belong_to_many(:users).class_name StrongBolt::Configuration.user_class }
    it { is_expected.to have_and_belong_to_many(:roles).class_name "StrongBolt::Role" }
    it { is_expected.to have_many(:capabilities).through :roles }

  end

end