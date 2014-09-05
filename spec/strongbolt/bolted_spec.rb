require "spec_helper"

module StrongBolt

  describe Bolted do
    
    #
    # Bolted?
    #
    describe "bolted?" do

      context 'when grant is disabled' do
        it "should return false" do
          without_grant do
            expect(Model.bolted?).to eq false
          end
        end
      end # End Grant disabled

      context "when no user" do
        before do
          expect(Grant::User).to receive(:current_user)
        end

        it "should return false" do
          expect(Model.bolted?).to eq false
        end
      end

      context "when using rails is on console" do
        before do
          rails = class_double 'Rails', :double => true
        end

        it "should return false" do
          expect(Model.bolted?).to eq false
        end
      end

    end

    it "should let create a model" do
      expect do
        Model.create! name: "Cool"
      end.not_to raise_error
    end

  end

end