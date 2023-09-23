Rails.application.routes.draw do
  devise_for :admins, skip: :all
  namespace :api do
    namespace :admin do
      devise_scope :admin do
        post "login", to: "sessions#create"
        delete "logout", to: "sessions#destroy"
      end
      resources :posts, only: %i[index create]
    end
  end
end
