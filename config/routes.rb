Rails.application.routes.draw do
  devise_for :users
  root "home#index"
  get "dashboard", to: "dashboard#show", as: :dashboard
  post "subscription/trial", to: "subscriptions#create_trial", as: :trial_subscription
  post "subscription/premium", to: "subscriptions#create_premium", as: :premium_subscription
  get "subscription/success", to: "subscriptions#success", as: :subscription_success
  get "subscription/cancel", to: "subscriptions#cancel", as: :subscription_cancel

  resources :exams, only: [ :index ] do
    resource :purchase, only: [ :create ], controller: "user_exams" do
      get :success
      get :cancel
    end
  end

  namespace :webhooks do
    post :stripe, to: "stripe#create"
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
end
