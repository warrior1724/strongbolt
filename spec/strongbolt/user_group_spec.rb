require 'spec_helper'

module Strongbolt
  describe UserGroup do
    let(:user_group) { UserGroup.new name: 'PCCC' }

    subject { user_group }

    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of :name }

    it {
      is_expected.to have_many(:user_groups_users).class_name('Strongbolt::UserGroupsUser')
                                                  .dependent :restrict_with_exception
    }
    it { is_expected.to have_many(:users).through :user_groups_users }

    it {
      is_expected.to have_many(:roles_user_groups).class_name('Strongbolt::RolesUserGroup')
                                                  .dependent :delete_all
    }
    it { is_expected.to have_many(:roles).through :roles_user_groups }

    it { is_expected.to have_many(:capabilities).through :roles }

    context 'when there are users linked to it' do
      before { user_group.users << User.create! }

      it 'cannot delete' do
        expect do
          user_group.destroy
        end.to raise_error ActiveRecord::DeleteRestrictionError
      end
    end
  end
end
