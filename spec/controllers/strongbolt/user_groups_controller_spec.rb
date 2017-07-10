require 'spec_helper'

module Strongbolt
  describe UserGroupsController do
    let!(:user_group) { Fabricate :user_group }

    let(:valid_attributes) { Fabricate.attributes_for :user_group }

    subject { response }

    #
    # GET #index
    #
    describe 'GET #index' do
      before { get :index }

      it { should be_success }

      it { should render_template :index }

      it 'should assign user groups' do
        expect(assigns(:user_groups)).to eq [user_group]
      end
    end

    #
    # GET #new
    #
    describe 'GET #new' do
      before { get :new }

      it { should be_success }

      it { should render_template :new }
    end

    #
    # GET #show
    #
    describe 'GET #show' do
      before { get :show, id: user_group.id }

      it { should be_success }

      it 'should assign user group' do
        expect(assigns(:user_group)).to eq user_group
      end

      it { should render_template :show }
    end

    #
    # GET #edit
    #
    describe 'GET #edit' do
      before { get :edit, id: user_group.id }

      it { should be_success }

      it 'should assign user group' do
        expect(assigns(:user_group)).to eq user_group
      end

      it { should render_template :edit }
    end

    #
    # POST #create
    #
    describe 'POST #create' do
      let(:create) { post :create, user_group: attributes }

      context 'when valid attributes' do
        let(:attributes) { valid_attributes }

        it 'should redirect to show' do
          create
          expect(response).to redirect_to user_group_path(UserGroup.last)
        end

        it 'should create an user group' do
          expect do
            create
          end.to change(UserGroup, :count).by 1
        end
      end

      context 'when invalid attributes' do
        let(:attributes) { {} }

        it 'should redirect_to new' do
          create
          expect(response).to redirect_to new_user_group_path
        end

        it 'should not create an user group' do
          expect do
            create
          end.not_to change(UserGroup, :count)
        end

        it 'should set flash danger' do
          create
          expect(flash[:danger]).to be_present
        end
      end
    end

    #
    # PUT #update
    #
    describe 'PUT #update' do
      before { put :update, id: user_group.id, user_group: attributes }

      context 'when valid attributes' do
        let(:attributes) { valid_attributes }

        it { should redirect_to user_group_path(user_group) }

        it 'should update attributes' do
          expect(user_group.reload.name).to eq valid_attributes[:name]
        end
      end

      context 'when invalid attributes' do
        let(:attributes) { { name: '' } }

        it { should redirect_to edit_user_group_path(user_group) }

        it 'should not update attributes' do
          expect(user_group.reload.name).not_to eq ''
        end

        it 'should set flash danger' do
          expect(flash[:danger]).to be_present
        end
      end
    end

    #
    # DELETE #destroy
    #
    describe 'DELETE #destroy' do
      let(:destroy) { delete :destroy, id: user_group.id }

      context 'when no user' do
        it 'should redirect to index' do
          destroy
          expect(response).to redirect_to user_groups_path
        end

        it 'should set flash success' do
          destroy
          expect(flash[:success]).to be_present
        end

        it 'should delete a user group' do
          expect do
            destroy
          end.to change(UserGroup, :count).by(-1)
        end
      end

      context 'when has users' do
        before { user_group.users << Fabricate(:user) }

        it 'should redirect to show' do
          destroy
          expect(response).to redirect_to user_group_path(user_group)
        end

        it 'should set flash danger' do
          destroy
          expect(flash[:danger]).to be_present
        end

        it 'should not delete a user group' do
          expect do
            destroy
          end.not_to change(UserGroup, :count)
        end
      end
    end
  end
end
