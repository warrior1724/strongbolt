require "spec_helper"

module StrongBolt

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
      end
    end

  end

end