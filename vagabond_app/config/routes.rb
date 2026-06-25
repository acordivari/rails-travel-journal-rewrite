Rails.application.routes.draw do
  root "home#index"

  # Authentication
  resource :session, only: %i[new create destroy]
  get "login",  to: "sessions#new"
  delete "logout", to: "sessions#destroy"

  resources :users

  resources :cities, except: %i[edit update] do
    resources :posts, shallow: true do
      resources :comments, only: %i[create destroy], shallow: true
    end
  end

  # Health check for load balancers / uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check

  # Catch-all 404 (must stay last).
  match "*unmatched", to: "errors#not_found", via: :all, constraints: ->(req) { req.path.exclude?("rails/active_storage") }
end
