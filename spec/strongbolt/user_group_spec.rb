require "spec_helper"

module Strongbolt

  describe UserGroup do
    
    let(:user_group) { UserGroup.new name: "PCCC" }

    subject { user_group }

    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of :name }

    it { is_expected.to have_and_belong_to_many(:users).class_name Strongbolt::Configuration.user_class }
    it { is_expected.to have_and_belong_to_many(:roles).class_name "Strongbolt::Role" }
    it { is_expected.to have_many(:capabilities).through :roles }

    context "when there are users linked to it" do
      before { user_group.users << User.create! }

      it "cannot delete" do
        expect do
          user_group.destroy
        end.to raise_error ActiveRecord::DeleteRestrictionError
      end
    end

  end

end