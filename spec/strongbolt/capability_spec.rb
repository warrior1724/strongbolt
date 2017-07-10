require 'spec_helper'

module Strongbolt
  describe Capability do
    let(:capability) { Capability.new model: 'User', action: 'find' }

    subject { capability }

    #
    # Associations
    #
    it {
      is_expected.to have_many(:capabilities_roles).class_name('Strongbolt::CapabilitiesRole')
                                                   .dependent :restrict_with_exception
    }
    it { is_expected.to have_many(:roles).through :capabilities_roles }
    it { is_expected.to have_many(:users).through :roles }

    #
    # VALIDATIONS
    #

    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of :model }
    it { is_expected.to validate_presence_of :action }

    it { is_expected.to validate_uniqueness_of(:action).scoped_to :model, :require_ownership, :require_tenant_access }

    it { is_expected.to validate_inclusion_of(:action).in_array %w[find create update destroy] }

    it 'should ensure the model exists' do
      capability.model = 'UserFake'
      expect(capability).not_to be_valid
    end

    context 'when there are roles linked to it' do
      before do
        capability.save
        capability.roles << Role.create!(name: 'role')
      end

      it 'cannot delete' do
        expect do
          capability.destroy
        end.to raise_error ActiveRecord::DeleteRestrictionError
      end
    end

    #
    # Scopes and table
    #
    describe 'scope and table' do
      before(:all) do
        define_model 'OtherModel'

        @capabilities = [
          Capability.create!(model: 'Model', action: 'find'),
          Capability.create!(model: 'Model', action: 'create'),
          Capability.create!(model: 'OtherModel', action: 'find'),
          Capability.create!(model: 'OtherModel', action: 'find', require_ownership: true),
          Capability.create!(model: 'User', action: 'find')
        ]
      end
      after(:all) { Capability.all.delete_all }

      #
      # SCOPE ORDERED
      #
      describe 'ordered' do
        it 'should have the scope' do
          expect(Capability).to respond_to :ordered
        end

        describe 'results' do
          let(:results) { Capability.ordered }

          subject { results }

          it 'should have 5 elements' do
            expect(results.size).to eq 5
          end

          it { should == @capabilities }
        end
      end

      #
      # To Table
      #
      describe 'to_table' do
        it 'should have the to_table' do
          expect(Capability).to respond_to :to_table
        end

        describe 'results' do
          let(:results) { Capability.to_table }

          subject { results }

          it 'should have 4' do
            expect(results.size).to eq 4
          end

          it 'should have each one as a hash with the right keys' do
            results.each do |permission|
              %i[model require_ownership require_tenant_access
                 find create update destroy].each do |attr|
                expect(permission).to include attr
              end
            end
          end
        end
      end # End to_table

      #
      # To Hash
      #
      describe 'to_hash' do
        it 'should have the to_hash' do
          expect(Capability).to respond_to :to_hash
        end

        describe 'results' do
          let(:results) { Capability.to_hash }

          subject { results }

          it 'should have 4' do
            expect(results.size).to eq 4
          end

          it 'should have the correct keys' do
            keys = [
              {
                model: 'Model',
                require_ownership: false,
                require_tenant_access: true
              },
              {
                model: 'OtherModel',
                require_ownership: false,
                require_tenant_access: true
              },
              {
                model: 'OtherModel',
                require_ownership: true,
                require_tenant_access: true
              },
              {
                model: 'User',
                require_ownership: false,
                require_tenant_access: true
              }
            ]
            results.each do |key, _permission|
              expect(keys).to include key
            end
          end

          it 'should have each one as a hash with the right keys' do
            results.each do |_key, permission|
              %i[find create update destroy].each do |attr|
                expect(permission).to include attr
              end
            end
          end
        end
      end # End to_hash
    end # End Scope and Table

    #
    # Create capability from hash
    #
    describe 'from_hash' do
      let(:params) { { model: 'User', require_ownership: true, require_tenant_access: false } }

      let(:capabilities) { Capability.from_hash params }

      subject { capabilities }

      context 'when list of actions' do
        before { params[:actions] = %i[find update] }

        it 'should have 2 element2' do
          expect(subject.size).to eq 2
        end

        it 'should have the right model' do
          capabilities.each do |c|
            expect(c.model).to eq 'User'
          end
        end

        it 'should have the right require_ownership' do
          capabilities.each { |c| expect(c.require_ownership).to eq true }
        end

        it 'should have the right require_tenant_access' do
          capabilities.each { |c| expect(c.require_tenant_access).to eq false }
        end

        it 'should have the right actions' do
          capabilities.each do |c|
            expect(%w[find update]).to include c.action.to_s
          end
        end
      end # /list of actions

      context 'when list of actions' do
        before { params[:actions] = 'find' }

        it 'should have 1 element' do
          expect(subject.size).to eq 1
        end

        it 'should have the right action' do
          expect(capabilities[0].action).to eq 'find'
        end
      end

      context 'when :all' do
        before { params[:actions] = 'all' }

        it 'should have 4 elements' do
          expect(subject.size).to eq 4
        end

        it 'should have the right actions' do
          capabilities.each do |c|
            expect(Capability::Actions).to include c.action.to_s
          end
        end
      end
    end
  end
end
