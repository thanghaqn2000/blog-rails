Rails.application.routes.draw do
  devise_for :admins, skip: :all
  namespace :api do
    namespace :admin do
      devise_scope :admin do
        post "login", to: "sessions#create"
        delete "logout", to: "sessions#destroy"
      end
      resources :refresh_tokens, only: :create
      resources :posts, only: %i[index create destroy update show] do
        collection do
          get :categories
        end
      end
    end

    namespace :v1 do
      resources :posts, only: %i[index show]
      resources :users, only: %i[create] do
        collection do
          get :check_info_uniqueness
        end
      end
    end
  end
end
