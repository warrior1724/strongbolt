require "spec_helper"

describe WithoutAuthorizationController do
  before do
    # Returns an user
    allow(Strongbolt).to receive(:current_user)
      .and_return User.new
  end

  describe "GET #show" do
    it "should not raise error" do
      expect { get :show }.not_to raise_error
    end

    it "should be success" do
      get :show
      expect(response).to be_success
    end
  end
end