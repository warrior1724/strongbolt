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

    it { is_expected.to validate_inclusion_of(:action).in_array %w{find create update destroy} }

    it "should ensure the model exists" do
      capability.model = "UserFake"
      expect(capability).not_to be_valid
    end

    context "when there are roles linked to it" do
        
      before do
        capability.save
        capability.roles << Role.create!(name: 'role')
      end

      it "cannot delete" do
        expect do
          capability.destroy
        end.to raise_error ActiveRecord::DeleteRestrictionError
      end

    end


    #
    # Scopes and table
    #
    describe "scope and table" do
      before(:all) do
        define_model "OtherModel"

        @capabilities = [
          Capability.create!(model: "Model", action: "find"),
          Capability.create!(model: "Model", action: "create"),
          Capability.create!(model: "OtherModel", action: "find"),
          Capability.create!(model: "OtherModel", action: "find", require_ownership: true),
          Capability.create!(model: "User", action: "find")
        ]
      end
      after(:all) { Capability.all.delete_all }

      #
      # SCOPE ORDERED
      #
      describe "ordered" do
        it "should have the scope" do
          expect(Capability).to respond_to :ordered
        end

        describe "results" do

          let(:results) { Capability.ordered }

          subject { results }

          it "should have 5 elements" do
            expect(results.size).to eq 5
          end

          it { should == @capabilities }
        end
      end

      #
      # To Table
      #
      describe "to_table" do
        
        it "should have the to_table" do
          expect(Capability).to respond_to :to_table
        end

        describe "results" do
          let(:results) { Capability.to_table }

          subject { results }

          it "should have 4" do
            expect(results.size).to eq 4
          end

          it "should have each one as a hash with the right keys" do
            results.each do |permission|
              [:model, :require_ownership, :require_tenant_access,
                :find, :create, :update, :destroy].each do |attr|
                  expect(permission).to include attr
                end
            end
          end
        end

      end

    end # End Scope and Table

  end

end