require 'spec_helper'

describe Strongbolt do
  #
  # Important included modules
  #
  it 'should have included Grant::Grantable in ActiveRecord::Base' do
    expect(ActiveRecord::Base.included_modules).to include Grant::Grantable
  end

  it 'should have included Bolted in ActiveRecord::Base' do
    expect(ActiveRecord::Base.included_modules).to include Strongbolt::Bolted
  end

  it 'should have included tentable' do
    expect(ActiveRecord::Base.included_modules).to include Strongbolt::Tenantable
  end

  #
  # Setting up
  #

  describe 'it should include module' do
    before do
      define_model 'UserModel'
      Strongbolt.setup do |config|
        config.user_class = 'UserModel'
      end
    end
    after do
      Strongbolt.setup do |config|
        config.user_class = 'User'
      end
    end

    it 'should include UserAbilities' do
      expect(UserModel.included_modules).to include Strongbolt::UserAbilities
    end
  end

  #
  # Access denied
  #
  describe 'access denied' do
    before do
      block = double('block', call: nil)
      expect(block).to receive(:call).with 'user', 'instance', 'action', 'request_path'
      Strongbolt::Configuration.access_denied do |user, instance, action, request_path|
        block.call user, instance, action, request_path
      end
    end
    after { Strongbolt::Configuration.access_denied {} }

    it "should call configuration's block" do
      Strongbolt.access_denied 'user', 'instance', 'action', 'request_path'
    end
  end

  #
  # Without authorization
  #
  describe 'without_authorization' do
    it 'should not perform authorization' do
      Strongbolt.without_authorization do
        expect(Grant::Status.grant_disabled?).to eq true
      end
    end

    describe 'perform action' do
      before do
        @user = User.create!
        Strongbolt.current_user = User.create!
      end
      after { Strongbolt.current_user = nil }

      let(:user) { @user }

      context 'with authorization' do
        it 'should call user can? when normal' do
          expect_any_instance_of(User).to receive(:can?)
            .with(:find, user).and_return true
          User.find user.id
        end
      end

      context 'when without_authorization' do
        it 'should not call can?' do
          Strongbolt.without_authorization do
            expect_any_instance_of(User).not_to receive(:can?)
            expect(User.find(user.id)).to eq user
          end
        end
      end
    end
  end

  #
  # Perform without authorization
  #
  describe 'perform_without_authorization' do
    before do
      define('AnyClass', Object) do
        def method(_arg1, _arg2)
          raise StandardError if Grant::Status.grant_enabled?
        end
      end
    end

    context 'when not skipped' do
      it 'should raise error' do
        expect do
          AnyClass.new.method('ok', 'ok2') {}
        end.to raise_error(StandardError)
      end
    end

    context 'when skipped' do
      before { AnyClass.perform_without_authorization :method }

      it 'should skip authorization' do
        expect do
          AnyClass.new.method('ok', 'ok2') {}
        end.not_to raise_error
      end
    end
  end

  #
  # Disable, enable
  #
  describe 'disable/enable' do
    before { Strongbolt.disable_authorization }
    after { Strongbolt.enable_authorization }

    context 'disabling' do
      it 'should disable Grant' do
        expect(Grant::Status.grant_enabled?).to eq false
        expect(Strongbolt.enabled?).to eq false
      end
    end

    context 'enabling' do
      it 'should enable Grant' do
        Strongbolt.enable_authorization
        expect(Grant::Status.grant_disabled?).to eq false
        expect(Strongbolt.disabled?).to eq false
      end
    end
  end

  #
  # Setting the Grant user
  #
  describe 'setting the current user' do
    context 'when it is from the same class then defined (or default)' do
      context "when the model doesn't have the module UserAbilities included" do
        before do
          define_model 'UserWithout' do
            self.table_name = 'users'
          end

          # We configure the user class
          Strongbolt::Configuration.user_class = 'UserWithout'
        end
        after { undefine_model 'UserWithout' }

        let(:user) { UserWithout.new }

        it 'should have included the module' do
          Strongbolt.current_user = user
          expect(UserWithout.included_modules).to include Strongbolt::UserAbilities
        end

        it 'should set the current user' do
          Strongbolt.current_user = user
          expect(Strongbolt.current_user).to eq user
          expect(Grant::User.current_user).to eq user
        end
      end # End when User Class doesn't have the UserAbilities included

      context 'when the model has the UserAbilities module included' do
        before do
          define_model 'UserWithAbilities' do
            include Strongbolt::UserAbilities
            self.table_name = 'users'
          end

          # We configure the user class
          Strongbolt::Configuration.user_class = 'UserWithAbilities'
        end
        after { undefine_model 'UserWithAbilities' }

        let(:user) { UserWithAbilities.new }

        it 'should set the current user' do
          Strongbolt.current_user = user
          expect(Strongbolt.current_user).to eq user
          expect(Grant::User.current_user).to eq user
        end
      end # End when User class has Abilities

      context 'when the user model is the base class of a STI' do
        before do
          define_model 'BaseUser' do
            self.table_name = 'users'
          end
          define 'UserWithSTI', BaseUser do
          end
          Strongbolt::Configuration.user_class = 'BaseUser'
        end

        let(:user) { UserWithSTI.new }

        it 'should allow setting as user a subclass' do
          Strongbolt.current_user = user
          expect(Strongbolt.current_user).to eq user
        end
      end # / end when user model is the base class of a STI

      context 'when the user model is a subclass of a STI' do
        before do
          define_model 'BaseUser' do
            self.table_name = 'users'
          end
          define 'UserWithSTI', BaseUser do
          end
          Strongbolt::Configuration.user_class = 'UserWithSTI'
        end

        let(:user) { UserWithSTI.new }

        it 'should allow setting as user a subclass' do
          Strongbolt.current_user = user
          expect(Strongbolt.current_user).to eq user
        end

        it 'should not allos the base class' do
          expect do
            Strongbolt.current_user = BaseUser.new
          end.to raise_error Strongbolt::WrongUserClass
        end
      end # / end when user model is the base class of a STI
    end # End when user given is the right class

    context "when the model isn't from the user class" do
      it 'should raise error' do
        Strongbolt::Configuration.user_class = 'User'
        expect do
          Strongbolt.current_user = Model.new
        end.to raise_error Strongbolt::WrongUserClass
      end
    end
  end
end
