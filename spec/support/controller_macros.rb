module ControllerMacros
  def login_user
    before(:each) do
      @user = Fabricate :user
      sign_in @user
    end
    let(:current_user) { @user }
  end
end
