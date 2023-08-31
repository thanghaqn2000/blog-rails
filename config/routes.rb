Rails.application.routes.draw do
  namespace :api do
    namespace :admin do
      resources :posts, only: %i(index create)
    end
  end
end
