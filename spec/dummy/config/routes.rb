Rails.application.routes.draw do

  strongbolt

  resources :posts do
    get :custom, on: :collection
  end
  resources :welcome

  get "without_authorization" => "without_authorization#show"
  
end
