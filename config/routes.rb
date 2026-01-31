Rails.application.routes.draw do
  # devise_for :admins, skip: :all
  devise_for :users, skip: :all
  
  # Mount Sidekiq Web UI (protect this in production)
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
  namespace :api do
    namespace :admin do
      resources :refresh_tokens, only: :create
      resources :posts, only: %i[index create destroy update show] do
        collection do
          get :categories
          post :presign
        end
      end
      resources :charts, only: :index do
        collection do
          post :upload_data
        end
      end
    end

    namespace :v1 do
      resources :posts, only: %i[index show]
      resources :refresh_tokens, only: :create
      resources :users, only: %i[create update] do
        collection do
          get :check_info_uniqueness
          post :verify_social_token
        end
      end
      devise_scope :user do
        post "login", to: "sessions#create"
        delete "logout", to: "sessions#destroy"
      end

      # Chatbot routes
      resources :conversations, only: %i[index show create update destroy] do
        member do
          patch :archive
          delete :delete_conversation
        end
        resources :messages, only: %i[index create] do
          collection do
            post :stream  # SSE streaming endpoint
          end
        end
      end
      
      # Quota check
      get 'quota', to: 'user_quotas#show'
    end
  end
end
