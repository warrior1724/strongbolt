require "spec_helper"

module Strongbolt
  describe UserGroupsUsersController do

    let(:user_group) { Fabricate :user_group }
    let(:user)       { Fabricate :user }

    subject { response }

    #
    # POST #create
    #
    describe "POST #create" do
      
      context "when valid user group and user" do
      
        before { post :create, user_group_id: user_group.id, id: user.id }

        it { should redirect_to user_group_path(user_group) }

        it "should have add user to group" do
          user_group.reload
          expect(user_group.users).to include user
        end

        context "when redoing" do
          before { post :create, user_group_id: user_group.id, id: user.id }

          it { should redirect_to user_group_path(user_group) }

          it "should not have added it twice" do
            expect(user_group.users.count).to eq 1
          end
        end

      end
    
    end

    #
    # DELETE #destroy
    #
    describe "DELETE #destroy" do
      context "when valid user group and user" do
        
        before do
          user_group.users << user
          delete :destroy, user_group_id: user_group.id, id: user.id
        end

        it { should redirect_to user_group_path(user_group) }

        it "should have removed user" do
          user_group.reload
          expect(user_group.users).not_to include user
        end

        context "when redoing" do
          before { delete :destroy, user_group_id: user_group.id, id: user.id }

          it { should redirect_to user_group_path(user_group) }
        end

      end
    end

  end
end