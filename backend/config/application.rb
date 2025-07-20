require_relative "boot"
require "logger"
require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie" if Rails.env.test?

Bundler.require(*Rails.groups)

module RentalManagerApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # CORS configuration
    config.middleware.use Rack::Cors do
      allow do
        origins '*' # Configure this properly for production
        resource '*',
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head]
      end
    end

    # Supabase configuration
    config.supabase_url = ENV.fetch('SUPABASE_URL', nil)
    config.supabase_anon_key = ENV.fetch('SUPABASE_ANON_KEY', nil)
    config.supabase_service_key = ENV.fetch('SUPABASE_SERVICE_KEY', nil)

    # AI configuration
    config.openai_api_key = ENV.fetch('OPENAI_API_KEY', nil)

    # Gmail OAuth configuration
    config.google_client_id = ENV.fetch('GOOGLE_CLIENT_ID', nil)
    config.google_client_secret = ENV.fetch('GOOGLE_CLIENT_SECRET', nil)
  end
end
