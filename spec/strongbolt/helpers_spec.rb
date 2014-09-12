require "spec_helper"
require "strongbolt/helpers"

describe StrongBolt::Helpers do

  let(:user) { @user }
  let(:helper) do
    @user = User.create!
    define("Helper", Object) do
      include StrongBolt::Helpers
    end
    Helper.send :define_method, :current_user do
      @user
    end
    Helper.new
  end
  
  describe "can?" do
    before do
      expect(user).to receive(:can?).with "find", "me"
    end

    it "should call the user method" do
      helper.can? "find", "me"
    end
  end
  
  describe "cannot?" do
    before do
      expect(user).to receive(:cannot?).with "find", "me"
    end

    it "should call the user method" do
      helper.cannot? "find", "me"
    end
  end

end