Rails.application.routes.draw do
  namespace :api do
    resources :users, except: [:new, :edit]
    resources :companies, except: [:new, :edit]
    resources :flights, except: [:new, :edit]
    resources :bookings, except: [:new, :edit]
    resource :session, only: [:create, :destroy]

    namespace :statistics do
      resources :flights, only: :index
      resources :companies, only: :index
    end
  end
end