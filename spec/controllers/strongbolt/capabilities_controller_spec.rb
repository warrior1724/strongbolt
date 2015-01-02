require "spec_helper"

module Strongbolt

  describe CapabilitiesController do

    subject { response }

    # #
    # # GET #index
    # #
    # describe "GET #index" do
      
    #   before do
    #     Fabricate :capability
    #     get :index
    #   end

    #   it { should be_success }

    #   it { should render_template :index }

    #   it "should assign capabilities" do
    #     expect(assigns :capabilities).to be_present
    #     expect(assigns(:capabilities).size).to be > 0
    #   end

    # end # End GET #index


    # #
    # # GET #show
    # #
    # describe "GET #show" do
    #   let(:capability) { Fabricate :capability }

    #   before { get :show, id: capability.id }

    #   it { should be_success }

    #   it { should render_template :show }

    #   it "should assign capability" do
    #     expect(assigns :capability).to be_present
    #   end
    # end

    #
    # POST #create
    #
    describe "POST #create" do

      let(:create) { post :create, capability: attributes }
      
      # context "when valid attributes" do
      #   let(:attributes) { Fabricate.attributes_for :capability }

      #   it "should redirect to capabilities list" do
      #     create
      #     expect(response).to redirect_to capabilities_path
      #   end

      #   it "should create a capability" do
      #     expect do
      #       create
      #     end.to change(Capability, :count).by 1
      #   end
      # end

      context "when valid attributes and role id present" do

        let(:role) { Fabricate :role }
        let(:attributes) { Fabricate.attributes_for :capability }

        context "html" do
          let(:create) { post :create, capability: attributes, role_id: role.id }

          it "should redirect to role" do
            create
            expect(response).to redirect_to role_path(role)
          end

          it "should add a capability to the role" do
            expect do
              create
            end.to change(role.capabilities, :count).by 1
          end
        end

        context "json" do |variable|
          let(:create) { post :create, capability: attributes, role_id: role.id, format: :json }

          it "should redirect to role" do
            create
            expect(response.code).to eq "200"
          end

          it "should add a capability to the role" do
            expect do
              create
            end.to change(role.capabilities, :count).by 1
          end
        end
      end

      # context "when same capability already exist" do
      #   let(:attributes) { Fabricate.attributes_for :capability }

      #   before do
      #     Fabricate :capability, attributes
      #   end

      #   it "should redirect to index" do
      #     create
      #     expect(response).to redirect_to capabilities_path
      #   end
      # end

      # context "when invalid attributes" do
      #   let(:attributes) { {} }

      #   it "should set flash danger" do
      #     create
      #     expect(flash[:danger]).to be_present
      #   end

      #   it "should redirect to index" do
      #     create
      #     expect(response).to redirect_to capabilities_path
      #   end
      # end

    end # END POST #create



    #
    # DELETE #destroy
    #
    describe "DELETE #destroy" do

      before do
        @capability = Fabricate :capability
      end

      let(:capability) { @capability }

      let(:destroy) { delete :destroy, id: capability.id }

      # context "when no roles" do

      #   it "should redirect to capabilities list" do
      #     destroy
      #     expect(response).to redirect_to capabilities_path
      #   end

      #   it "should delete a capability" do
      #     expect do
      #       destroy
      #     end.to change(Capability, :count).by -1
      #   end

      # end

      # context "when roles linked" do

      #   before do
      #     capability.roles << Fabricate(:role)
      #   end
        
      #   it "should redirect to capabilities list" do
      #     destroy
      #     expect(response).to redirect_to capability_path(capability)
      #   end

      #   it "should not delete a capability" do
      #     expect do
      #       destroy
      #     end.not_to change(Capability, :count)
      #   end

      #   it "should set flash danger" do
      #     destroy
      #     expect(flash[:danger]).to be_present
      #   end

      # end

      context "when role_id given" do
        let(:role) { Fabricate :role }
        
        before do
          role.capabilities << capability
        end

        context "when capability id given" do

          let(:destroy) { delete :destroy, id: capability.id, role_id: role.id }


          it "should not delete a capability" do
            expect do
              destroy
            end.not_to change(Capability, :count)
          end

          it "should remove the capability from role" do
            destroy
            role.reload
            expect(role.capabilities).not_to include capability
          end

          it "should redirect to role" do
            destroy
            expect(response).to redirect_to role_path(role)
          end

        end

        context "when capability data given and format json" do
          let(:attributes) do
            {model: capability.model, require_ownership: capability.require_ownership,
              require_tenant_access: capability.require_tenant_access,
              action: capability.action}
          end

          let(:destroy) { delete :destroy, role_id: role.id, capability: capability.attributes, format: :json }

          it "should not delete a capability" do
            expect do
              destroy
            end.not_to change(Capability, :count)
          end

          it "should remove the capability from role" do
            destroy
            role.reload
            expect(role.capabilities).not_to include capability
          end

          it "should render 200" do
            destroy
            expect(response.code).to eq "200"
          end
        end
      end


    end


  end

end