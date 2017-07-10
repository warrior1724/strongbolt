require 'spec_helper'

module Strongbolt
  describe RolesController do
    let!(:role) { Fabricate :role }

    let(:valid_attributes) { Fabricate.attributes_for :role }

    # login_user

    subject { response }

    #
    # GET #index
    #
    describe 'GET #index' do
      before { get :index }

      it { should be_success }

      it { should render_template :index }

      it 'should assign roles' do
        expect(assigns(:roles)).to eq [role]
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
      # Some children
      let(:role2) { Fabricate :role, parent: role }
      let!(:role3) { Fabricate :role, parent: role2 }

      before { get :show, id: role.id }

      it { should be_success }

      it 'should assign role' do
        expect(assigns(:role)).to eq role
      end

      it 'should assign children' do
        expect(assigns(:descendants)).to eq [role2, role3]
      end

      it { should render_template :show }
    end

    #
    # GET #edit
    #
    describe 'GET #edit' do
      before { get :edit, id: role.id }

      it { should be_success }

      it 'should assign role' do
        expect(assigns(:role)).to eq role
      end

      it { should render_template :edit }
    end

    #
    # POST #create
    #
    describe 'POST #create' do
      let(:create) { post :create, role: attributes }

      context 'when valid attributes' do
        let(:attributes) { valid_attributes }

        it 'should redirect to show' do
          create
          expect(response).to redirect_to role_path(Role.last)
        end

        it 'should create an role' do
          expect do
            create
          end.to change(Role, :count).by 1
        end
      end

      context 'when invalid attributes' do
        let(:attributes) { {} }

        it 'should redirect_to new' do
          create
          expect(response).to redirect_to new_role_path
        end

        it 'should not create a role' do
          expect do
            create
          end.not_to change(Role, :count)
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
      before { put :update, id: role.id, role: attributes }

      context 'when valid attributes' do
        let(:attributes) { valid_attributes }

        it { should redirect_to role_path(role) }

        it 'should update attributes' do
          expect(role.reload.name).to eq valid_attributes[:name]
        end
      end

      context 'when invalid attributes' do
        let(:attributes) { { name: '' } }

        it { should redirect_to edit_role_path(role) }

        it 'should not update attributes' do
          expect(role.reload.name).not_to eq ''
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
      let(:destroy) { delete :destroy, id: role.id }

      context 'when no user' do
        it 'should redirect to index' do
          destroy
          expect(response).to redirect_to roles_path
        end

        it 'should set flash success' do
          destroy
          expect(flash[:success]).to be_present
        end

        it 'should delete a role' do
          expect do
            destroy
          end.to change(Role, :count).by(-1)
        end
      end

      context 'when has user groups' do
        let(:role) { Fabricate :role_with_user_groups }

        it 'should redirect to show' do
          destroy
          expect(response).to redirect_to role_path(role)
        end

        it 'should set flash danger' do
          destroy
          expect(flash[:danger]).to be_present
        end

        it 'should not delete a role' do
          expect do
            destroy
          end.not_to change(Role, :count)
        end
      end
    end
  end
end
