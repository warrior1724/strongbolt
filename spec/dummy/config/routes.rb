Rails.application.routes.draw do
  resources :posts do
    get :custom, on: :collection
  end
  resources :welcome
end
