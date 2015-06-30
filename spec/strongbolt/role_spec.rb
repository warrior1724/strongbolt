require "spec_helper"

module Strongbolt

  describe Role do
    
    let(:role) { Role.new name: 'Moderator' }

    subject { role }

    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of :name }

    it { is_expected.to have_many(:roles_user_groups).class_name("Strongbolt::RolesUserGroup")
      .dependent :restrict_with_exception }
    it { is_expected.to have_many(:user_groups).through :roles_user_groups }

    it { is_expected.to have_many(:users).through :user_groups  }
    
    it { is_expected.to have_many(:capabilities_roles).class_name("Strongbolt::CapabilitiesRole")
      .dependent :delete_all }
    it { is_expected.to have_many(:capabilities).through :capabilities_roles }

    it { is_expected.to belong_to(:parent).class_name("Strongbolt::Role") }

    describe "inherited capabilities" do
      
      before do
        # A family
        grandfather = Role.create! name: "GrandFather"
        father = Role.create! name: "Father", parent: grandfather
        sibling = Role.create! name: "Sibling"
        role.parent = father
        role.save!
        child = Role.create! name: "Child", parent: role

        # Some capabilities
        begin
          role.capabilities.create! model: "Model", action: "create"
        rescue => e
          puts e.record.capabilities_roles[0].errors.full_messages
        end
        child.capabilities.create! model: "Model", action: "destroy"
        @inherited1 = father.capabilities.create! model: "Model", action: "update"
        @inherited2 = grandfather.capabilities.create! model: "Model", action: "find"
        sibling.capabilities.create! model: "User", action: "find"
      end

      let(:inherited_capabilities) { role.inherited_capabilities }

      it "should have 2 inherited_capabilities" do
        expect(inherited_capabilities.size).to eq 2
      end

      it "should have the right ones" do
        expect(inherited_capabilities).to include @inherited1
        expect(inherited_capabilities).to include @inherited2
      end

    end

    describe 'destroy' do |variable|
      before { role.save! }

      context "when have user groups" do
        before { role.user_groups << UserGroup.create!(name: "User Group") }

        it "should raise error when destroy" do
          expect do
            role.destroy
          end.to raise_error ActiveRecord::DeleteRestrictionError
        end
      end

      context "when have children" do
        before { Role.create! name: "Child", parent: role }

        it "should raise an error when destroy" do
          expect do
            role.destroy
          end.to raise_error ActiveRecord::DeleteRestrictionError
        end
      end

    end

  end

end