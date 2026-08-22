Rails.application.routes.draw do
  resources :readings
  resources :books
  resources :series
  resources :shelves do
    resources :shelf_books, only: [:create, :destroy], path: "books"
  end
  get "book_search", to: "book_search#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get "up" => "rails/health#show", :as => :rails_health_check

  root "readings#index"

  resources :passwords, controller: "clearance/passwords", only: [:new, :create, :edit, :update]
  resource :session, controller: "sessions", only: [:new, :create, :destroy]
  resources :users, controller: "clearance/users", only: [:new, :create]
  resources :users, controller: "profiles", only: [:show] do
    member do
      get :followers
      get :following
    end
    resource :follow, only: [:create, :destroy]
  end

  resource :account, only: [:edit, :update, :destroy]
  resource :email_confirmation, only: [:create]
  get "confirm_email/:token", to: "email_confirmations#confirm", as: :confirm_email

  namespace :admin do
    root "dashboard#index"
    resources :users, only: [:index, :edit, :update]
    resources :readings, only: [:index]
  end
end
