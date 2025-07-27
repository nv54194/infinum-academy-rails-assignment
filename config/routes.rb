Rails.application.routes.draw do
  namespace :api do
    resources :users, except: [:new, :edit]
    resources :companies, except: [:new, :edit]
    resources :flights, except: [:new, :edit]
    resources :bookings, except: [:new, :edit]
    resources :session, only: [:create, :destroy]
  end
end
