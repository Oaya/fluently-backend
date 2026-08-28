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
        invitations: "api/auth/invitations",
        passwords: "api/auth/passwords"
      },
      only: [ :registrations, :sessions, :confirmations, :invitations, :passwords ]

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

    resources :invoices, only: [ :index, :create, :update, :destroy, :show ]

    resources :users, only: [ :index, :show, :update, :destroy ] do
      collection do
        get :with_statues
      end
    end

    resources :plans, only: [ :index ]

    resources :lessons, only: [ :index, :create, :update, :destroy, :show ] do
      collection do
        get "today", to: "lessons#today"
      end
      member do
        get :token
        patch :end
        patch :student_note
        patch :meeting_note
        patch :cancel
      end
      resource :recording, only: [ :show, :create ], controller: "lesson_recordings"
    end

    resources :homeworks, only: [ :index, :show, :create, :update, :destroy ] do
      collection do
        post :ai_generate
      end
    end


    resources :homework_submissions, only: [ :index, :show, :create, :destroy ] do
      member do
        patch :feedback
      end
    end

    resources :goals, only: [ :index, :show, :create, :update, :destroy ] do
      member do
        post :activity
        patch :activity, action: :update_activity
        delete "activity/:activity_id", action: :destroy_activity, as: :destroy_activity

        post :comment
        delete "comment/:comment_id", action: :destroy_comment, as: :destroy_comment
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
