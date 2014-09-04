require "spec_helper"

describe StrongBolt do
  
  #
  # Important included modules
  #
  it "should have included Grant::Grantable in ActiveRecord::Base" do
    expect(ActiveRecord::Base.included_modules).to include Grant::Grantable  
  end

  it "should have included Bolted in ActiveRecord::Base" do
    expect(ActiveRecord::Base.included_modules).to include StrongBolt::Bolted
  end

  #
  # Access denied
  #
  describe "access denied" do
    
    before do
      block = double('block', :call => nil)
      expect(block).to receive(:call).with 'user', 'instance', 'action', 'request_path'
      StrongBolt::Configuration.access_denied do |user, instance, action, request_path|
        block.call user, instance, action, request_path
      end
    end

    it "should call configuration's block" do
      StrongBolt.access_denied 'user', 'instance', 'action', 'request_path'
    end

  end

end