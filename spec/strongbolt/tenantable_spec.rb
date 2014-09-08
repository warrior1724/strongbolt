require "spec_helper"

module StrongBolt

  #
  # Set up a series of models to test the tenant setup
  #
  class TenantModel < Model
    has_many :child_models

    belongs_to :parent, class_name: "::StrongBolt::UnownedModel",
      foreign_key: :parent_id
  end

  class ChildModel < ActiveRecord::Base
    self.table_name = "child_models"

    belongs_to :tenant_model, foreign_key: :model_id,
      class_name: "::StrongBolt::TenantModel"

    has_many :other_child_models, class_name: "::StrongBolt::OtherChildModel"
  end

  class OtherChildModel < ActiveRecord::Base
    self.table_name = "child_models"

    belongs_to :child_model, foreign_key: :model_id,
      class_name: "::StrongBolt::ChildModel"
    belongs_to :uncle_model, foreign_key: :parent_id,
      class_name: "::StrongBolt::UncleModel"
    has_one :sibling_model, class_name: "::StrongBolt::SiblingModel"

    has_and_belongs_to_many :bottom_models,
      class_name: "::StrongBolt::BottomModel",
      foreign_key: :parent_id,
      association_foreign_key: :child_id
  end

  class UncleModel < ActiveRecord::Base
    self.table_name = "models"

    has_many :other_child_models, class_name: "::StrongBolt::OtherChildModel"
    belongs_to :parent, class_name: "::StrongBolt::UnownedModel",
      foreign_key: :parent_id
  end

  class SiblingModel < ActiveRecord::Base
    self.table_name = "child_models"

    belongs_to :other_child_model, foreign_key: :model_id,
      class_name: "::StrongBolt::OtherChildModel"
  end 

  UnownedModel.has_many :tenant_models, foreign_key: :parent_id
  # UnownedModel.has_many :uncle_models, foreign_key: :parent_id

  class BottomModel < ActiveRecord::Base
    self.table_name = "models"

    has_and_belongs_to_many :other_child_models,
      class_name: "::StrongBolt::OtherChildModel",
      join_table: "model_models",
      foreign_key: :child_id,
      association_foreign_key: :parent_id,
      inverse_of: :bottom_models

  end

  describe Tenantable do
    
    it "should have been included in ActiveRecord::Base" do
      expect(ActiveRecord::Base.included_modules).to include Tenantable
    end

    describe 'tenant?' do
      context "when class is not a tenant" do
        before do
          class OtherModel < Model
          end
        end
        #after { Object.send :remove_const, 'OtherModel' }

        it "should return false" do
          expect(OtherModel.tenant?).to eq false
        end
      end

      context "when class is a tenant" do
        before do
          class OtherModel < Model
            tenant
          end
        end
        #after { Object.send :remove_const, 'OtherModel' }

        it "should return true" do
          expect(OtherModel.tenant?).to eq true
        end

        it "should add the model to the list of tenants" do
          expect(StrongBolt.tenants).to include OtherModel
        end
      end
    end

    #
    # Tenant setup
    #
    describe "tenant setup" do
      
      before(:all) do
        TenantModel.tenant
      end

      it "should have added has_one :tenant_model to other child model" do
        expect(OtherChildModel.new).to have_one(:tenant_model).through(:child_model)
      end

      it "should have added has_many :tenant_models to BottomModel" do
        expect(BottomModel.new).to have_many(:tenant_models).through :other_child_models
      end

      it "should have created a has_one :tenant_model to SiblingModel" do
        expect(SiblingModel.new).to have_one(:tenant_model).through :other_child_model
      end

      it "should have added has_many :tenant_models to UncleModel" do
        expect(UncleModel.new).to have_many(:tenant_models).through :other_child_models
      end

    end

  end

end