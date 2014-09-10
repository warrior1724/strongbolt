require "spec_helper"

describe StrongBolt::Configuration do
  

  #
  # User class
  #
  describe "user class" do
    
    it "should default to User" do
      expect(StrongBolt::Configuration.user_class).to eq "User"
    end

    context "when setting it" do
      before { StrongBolt::Configuration.user_class = "Account" }
      after { StrongBolt::Configuration.user_class = "User" }

      it "should give it" do
        expect(StrongBolt::Configuration.user_class).to eq "Account"
      end
    end

  end

end