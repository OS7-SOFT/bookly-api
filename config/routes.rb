Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      get "auth/me", to: "auth#me"

      resources :businesses, only: [ :index, :show, :create, :update ] do
        resources :bookable_services, only: [ :index, :create ]
        resources :working_hours, only: [ :index, :create ]
        resources :bookings, only: [ :index, :create ]

        get :availability, to: "availability#show"
      end

      resources :bookable_services, only: [ :show, :update, :destroy ]
      resources :working_hours, only: [ :show, :update, :destroy ]

      resources :bookings, only: [ :show ] do
        member do
          patch :confirm
          patch :cancel
          patch :complete
          patch :no_show
        end
      end
    end
  end
end
