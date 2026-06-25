Rails.application.routes.draw do
  get "/", to: proc { [ 200, {}, [ "OK" ] ] }

  namespace :api, defaults: { format: :json } do
    devise_for :users,
      path: "auth",
      defaults: { format: :json },
      controllers: {
        registrations: "api/auth/registrations",
        sessions: "api/auth/sessions",
        confirmations: "api/auth/confirmations",
        invitations: "api/auth/invitations"
      },
      only: [ :registrations, :sessions, :confirmations, :invitations ]

    # Not Devise routes, but still auth-related, so putting here for now
    namespace :auth do
      resources :me, only: [] do
        collection do
          get "", to: "users#me"
          patch "", to: "users#update_me"
          patch "password", to: "users#update_password"
        end
      end
    end

    resources :users, only: [ :index, :show, :update, :destroy ] do
      collection do
        delete :bulk_delete
      end
    end

    resources :plans, only: [ :index ]

    resources :sessions, only: [ :index, :create, :update, :destroy ] do
      collection do
        get "today", to: "sessions#today"
      end
      member do
        patch :cancel
      end
    end

    resource :subscription, only: [] do
      collection do
        post :cancel
        post :change_plan
        post :payment_checkout
      end
    end





    # Active Storage direct upload endpoint
    post "rails/active_storage/direct_uploads", to: "active_storage/direct_uploads#create"


    # Stripe webhook endpoint
    post "stripe/webhook", to: "stripe_webhooks#receive"
  end
end
