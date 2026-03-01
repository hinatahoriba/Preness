Rails.application.routes.draw do
  if Rails.env.development?
    begin
      require "letter_opener_web"
      mount LetterOpenerWeb::Engine, at: "/letter_opener"
    rescue LoadError
      Rails.logger.warn("letter_opener_web is not available. Run bundle install in this environment.")
    end
  end

  devise_for :users, skip: [:registrations]

  as :user do
    get "users/sign_up", to: "users/registrations#new", as: :new_user_registration
    post "users", to: "users/registrations#create", as: :user_registration
    get "users/edit", to: "users/registrations#edit", as: :edit_user_registration
    patch "users", to: "users/registrations#update"
    put "users", to: "users/registrations#update"
  end

  get "users/confirmation/pending", to: "auth#confirmation_pending", as: :user_confirmation_pending
  resource :mypage, only: [:show]
  get "terms", to: "pages#terms", as: :terms
  get "privacy", to: "pages#privacy", as: :privacy

  resources :exercises, only: [:index] do
    member do
      match :answer, via: %i[get post]
      get :result
    end
  end

  namespace :api do
    namespace :v1 do
      resources :mocks, only: [:create]
      resources :exercises, only: [:create]
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
