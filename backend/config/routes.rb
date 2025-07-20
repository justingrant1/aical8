Rails.application.routes.draw do
  # Health check endpoint
  get '/health', to: 'health#check'

  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication routes
      post 'auth/login', to: 'auth#login'
      post 'auth/refresh', to: 'auth#refresh' 
      post 'auth/logout', to: 'auth#logout'
      
      # Gmail OAuth routes
      get 'gmail/auth_url', to: 'gmail#auth_url'
      post 'gmail/callback', to: 'gmail#callback'
      get 'gmail/accounts', to: 'gmail#accounts'
      delete 'gmail/accounts/:id', to: 'gmail#disconnect'
      post 'gmail/sync', to: 'gmail#sync'
      get 'gmail/sync_status', to: 'gmail#sync_status'
      
      # Dashboard
      get 'dashboard', to: 'dashboard#index'
      
      # Properties management
      resources :properties do
        member do
          patch :update_status
        end
        collection do
          get :search
          get :occupancy_report
        end
        
        # Nested tasks for properties
        resources :tasks, only: [:index, :create]
      end
      
      # Tasks management
      resources :tasks do
        member do
          patch :complete
          patch :assign
          post :add_feedback
        end
        collection do
          get :overdue
          get :due_soon
          get :search
        end
      end
      
      # Email management
      resources :emails, only: [:index, :show] do
        member do
          post :mark_processed
          post :create_task
        end
        collection do
          get :search
          get :unprocessed
          get :by_category
        end
      end
      
      # Email accounts (OAuth integration)
      resources :email_accounts, only: [:index, :show, :create, :update, :destroy] do
        member do
          post :connect_gmail
          post :disconnect
          post :sync_now
          patch :update_settings
        end
      end
      
      # Organization management
      resource :organization, only: [:show, :update] do
        resources :users, only: [:index, :show, :create, :update, :destroy], controller: 'user_profiles' do
          member do
            patch :update_role
            patch :deactivate
            patch :activate
          end
        end
      end
      
      # AI Analysis logs (for debugging and monitoring)
      resources :ai_analysis_logs, only: [:index, :show] do
        member do
          post :provide_feedback
        end
        collection do
          get :statistics
        end
      end
      
      # Admin endpoints (for system admins)
      namespace :admin do
        resources :organizations, only: [:index, :show, :update] do
          member do
            patch :update_subscription
            patch :suspend
            patch :reactivate
          end
        end
        
        get 'system_stats', to: 'dashboard#system_stats'
        get 'usage_analytics', to: 'dashboard#usage_analytics'
      end
    end
  end
  
  # OAuth callbacks
  namespace :auth do
    namespace :callbacks do
      get 'gmail', to: 'gmail#callback'
    end
  end
  
  # Webhooks
  namespace :webhooks do
    post 'gmail_notifications', to: 'gmail#notifications'
  end
end
