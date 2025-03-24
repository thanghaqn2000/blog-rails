Rails.application.routes.draw do
  # devise_for :admins, skip: :all
  devise_for :users, skip: :all
  namespace :api do
    namespace :admin do
      resources :refresh_tokens, only: :create
      resources :posts, only: %i[index create destroy update show] do
        collection do
          get :categories
        end
      end
    end

    namespace :v1 do
      resources :posts, only: %i[index show]
      resources :refresh_tokens, only: :create
      resources :users, only: %i[create] do
        collection do
          get :check_info_uniqueness
        end
      end
      devise_scope :user do
        post "login", to: "sessions#create"
        delete "logout", to: "sessions#destroy"
      end
    end
  end
end
