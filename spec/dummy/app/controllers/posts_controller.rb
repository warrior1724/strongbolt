#
# We create the controller we'll be using in our tests
#
RESTFUL_ACTIONS = [:index, :show, :new, :create, :update, :edit, :destroy]

class PostsController < TestController
  include Strongbolt::BoltedController

  # Some actions
  RESTFUL_ACTIONS.each do |action|
    define_method action do
    end
  end

  def custom; end

  def current_user; end
end