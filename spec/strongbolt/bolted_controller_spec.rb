require "spec_helper"

#
# We create the controller we'll be using in our tests
#
class PostsController < TestController
  # Some actions
  [:index, :show, :new, :create, :update, :edit, :destroy].each do |action|
    define_method action do
      #render nothing: true
    end
  end

  def current_user(); end
end

# We're testing BoltedController module through this one
describe PostsController, :type => :controller do
  
  before(:all) do
    PostsController.send :include, StrongBolt::BoltedController
    define_model "Post"
    @user = User.create!
  end

  let(:user) { @user }



  #
  # Before Filter, set current user
  #
  describe 'before_filter' do

    before do
      PostsController.skip_after_filter :unset_current_user
      PostsController.skip_before_filter :check_authorization
    end
    after do
      PostsController.after_filter :unset_current_user
      PostsController.before_filter :check_authorization
    end
    
    context 'when no user' do
      before do
        expect_any_instance_of(PostsController).to receive(:current_user)
          .at_least(1).times.and_return nil
        get :index
      end
    
      it "should set nil user" do
        expect(StrongBolt.current_user).to be_nil
      end

      it "should have set $request" do
        expect($request).to be_present
      end
    end

    context "when user" do
      let(:user) { User.new }

      before do
        expect_any_instance_of(PostsController).to receive(:current_user).and_return user
        get :index
      end
    
      it "should set the user" do
        expect(StrongBolt.current_user).to eq user
      end
    end

  end

  #
  # After filter, unset current user
  #
  describe 'after_filter' do

    before do
      PostsController.skip_before_filter :check_authorization
    end
    after do
      PostsController.before_filter :check_authorization
    end
    
    context "when a user is set" do
      let(:user) { User.new }

      before do
        expect_any_instance_of(PostsController).to receive(:current_user).and_return user
        get :index
      end
    
      it "should have unsetted the user" do
        expect(StrongBolt.current_user).to be_nil
      end
    end

  end


  #
  # Checking authorization on a high level
  #
  describe "checking authorization" do
    
    before(:all) do
      # Model linked to the controller
      define_model "Post" do
        self.table_name = "models"
      end
    end

    before do
      # user is the current user of our app
      allow_any_instance_of(PostsController).to receive(:current_user)
        .and_return user
    end


    #
    # Call the right CRUD operation
    #
    describe "calling the CRUD operations" do
      {
        :index    => :find,
        :show     => :find,
        :edit     => :update,
        :update   => :update,
        :new      => :create,
        :create   => :create
      }.each do |action, operation|
        context "when calling #{action}" do
          it "should call the operation" do
            expect(user).to receive(:can?).with(operation, Post).and_return true
            case action
            when :index, :new then get action
            when :show, :edit then get action, id: 1
            when :update then put :update, id: 1
            when :create then post :create
            end
          end
        end
      end # End checking calling right can
    end


    #
    # When not authorized
    #
    context "when not authorized" do
      before do
        expect(StrongBolt).to receive(:access_denied)
        expect(user).to receive(:can?).and_return false
      end

      it "should raise StrongBolt::Unauthorized" do
        expect do
          get :index
        end.to raise_error StrongBolt::Unauthorized
      end
    end

    #
    # When authorized
    #
    context "when authorized" do
      before do
        expect(user).to receive(:can?).and_return true
      end

      it "should not raise error" do
        expect do
          get :index
        end.not_to raise_error
      end
    end

  end

end