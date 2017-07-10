class WithoutAuthorizationController < ApplicationController
  def show
    head :ok
  end
end
