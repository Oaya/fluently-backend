Rails.application.routes.draw do
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
        get :instructors
        delete :bulk_delete
      end
      member do
        get :courses
        get :enrollments

        get "courses/:course_id/status", to: "users#course_status"
      end
    end

    resources :plans, only: [ :index ]

    resources :courses do
      resources :sections, only: [ :index, :create ] do
        collection { put :reorder }
      end
      member do
        get :overview
        patch :price
        patch :publish
      end
    end

    resources :sections, only: [ :show, :update, :destroy ] do
      resources :lessons, only: [ :index, :create ] do
        collection { put :reorder }
      end
    end

    resources :lessons, only: [ :show, :update, :destroy ]

    resources :enrollments, only: [] do
      member do
        post :start
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
