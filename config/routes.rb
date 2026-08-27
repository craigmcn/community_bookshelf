Rails.application.routes.draw do
  resources :readings do
    resource :review_like, only: [:create, :destroy]
    resources :review_comments, only: [:create, :destroy]
    collection do
      get :export
    end
  end
  resource :goodreads_import, only: [:new, :create]
  resources :books
  resources :series
  resources :reading_challenges, only: [:index, :new, :create, :edit, :update]
  resources :shelves do
    resources :shelf_books, only: [:create, :destroy], path: "books"
  end
  get "book_search", to: "book_search#index"
  get "feed", to: "activities#index"
  resource :stats, only: [:show]
  resources :notifications, only: [:index, :update] do
    collection do
      patch :mark_all_read
    end
  end
  resources :buddy_reads, only: [:index, :new, :create, :show, :update] do
    resources :messages, only: [:create], controller: "buddy_read_messages"
  end
  resources :clubs do
    resource :membership, only: [:create, :destroy], controller: "club_memberships"
    resources :posts, only: [:create, :destroy], controller: "club_posts"
  end
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

  resource :account, only: [:edit, :update, :destroy] do
    post :regenerate_api_token, on: :collection
  end
  resource :email_confirmation, only: [:create]
  get "confirm_email/:token", to: "email_confirmations#confirm", as: :confirm_email

  namespace :admin do
    root "dashboard#index"
    resources :users, only: [:index, :edit, :update]
    resources :readings, only: [:index]
  end

  namespace :api do
    namespace :v1 do
      resources :books
      resources :readings
    end
  end
end
