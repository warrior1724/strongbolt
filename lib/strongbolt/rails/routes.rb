module ActionDispatch::Routing
  #
  # Creates the strongbolt route helper method
  #
  class Mapper
    def strongbolt
      namespace :strongbolt do
        resources :user_groups do
          resources :user_groups_users, as: :users, path: 'users', only: [:create, :destroy]
        end

        resources :roles do
          resources :capabilities, only: [:create, :destroy] do
            delete :destroy, on: :collection
          end
        end
      end
    end
  end
end