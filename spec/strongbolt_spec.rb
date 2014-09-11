require "spec_helper"

describe StrongBolt do
  
  #
  # Important included modules
  #
  it "should have included Grant::Grantable in ActiveRecord::Base" do
    expect(ActiveRecord::Base.included_modules).to include Grant::Grantable  
  end

  it "should have included Bolted in ActiveRecord::Base" do
    expect(ActiveRecord::Base.included_modules).to include StrongBolt::Bolted
  end

  it "should have included tentable" do
    expect(ActiveRecord::Base.included_modules).to include StrongBolt::Tenantable
  end

  #
  # Access denied
  #
  describe "access denied" do
    
    before do
      block = double('block', :call => nil)
      expect(block).to receive(:call).with 'user', 'instance', 'action', 'request_path'
      StrongBolt::Configuration.access_denied do |user, instance, action, request_path|
        block.call user, instance, action, request_path
      end
    end

    it "should call configuration's block" do
      StrongBolt.access_denied 'user', 'instance', 'action', 'request_path'
    end

  end

  #
  # Setting the Grant user
  #
  describe 'setting the current user' do

    context "when it is from the same class then defined (or default)" do

      context "when the model doesn't have the module UserAbilities included" do
        before do
          define_model "UserWithout" do
            self.table_name = 'users'
          end
          
          # We configure the user class
          StrongBolt::Configuration.user_class = 'UserWithout'
        end
        after { undefine_model "UserWithout" }

        let(:user) { UserWithout.new }

        it "should have included the module" do
          StrongBolt.current_user = user
          expect(UserWithout.included_modules).to include StrongBolt::UserAbilities
        end

        it "should set the current user" do
          StrongBolt.current_user = user
          expect(StrongBolt.current_user).to eq user
          expect(Grant::User.current_user).to eq user
        end
      end # End when User Class doesn't have the UserAbilities included
      
      context 'when the model has the UserAbilities module included' do
        
        before do
          define_model "UserWithAbilities" do
            include StrongBolt::UserAbilities
            self.table_name = 'users'
          end
          
          # We configure the user class
          StrongBolt::Configuration.user_class = 'UserWithAbilities'
        end
        after { undefine_model "UserWithAbilities" }
        
        let(:user) { UserWithAbilities.new }

        it "should set the current user" do
          StrongBolt.current_user = user
          expect(StrongBolt.current_user).to eq user
          expect(Grant::User.current_user).to eq user
        end

      end # End when User class has Abilities

    end # End when user given is the right class

    context "when the model isn't from the user class" do
      
      it "should raise error" do
        expect do
          StrongBolt.current_user = Model.new
        end.to raise_error StrongBolt::WrongUserClass
      end

    end

  end

end