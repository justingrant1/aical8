source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.4'

# Core Rails gems
gem 'rails', '~> 7.0.0', '>= 7.0.4.2'
gem 'pg', '~> 1.1'  # PostgreSQL adapter
gem 'puma', '~> 5.0'  # Web server

# API-specific gems
gem 'rack-cors'  # CORS handling for frontend
gem 'jbuilder', '~> 2.7'  # JSON views

# Authentication & Authorization
gem 'jwt'  # JWT token handling
gem 'bcrypt', '~> 3.1.7'  # Password encryption

# Background jobs
gem 'sidekiq'  # Background job processing
gem 'redis', '~> 4.0'  # Redis for Sidekiq

# HTTP client for external APIs
gem 'httparty'  # Gmail API calls
gem 'faraday'  # HTTP client
gem 'oauth2'  # OAuth2 flow
gem 'signet'  # Google OAuth2 client
gem 'google-api-client'  # Google APIs client library

# AI & ML
gem 'ruby-openai'  # OpenAI API client

# Utilities
gem 'dotenv-rails'  # Environment variables
# gem 'bootsnap', '>= 1.4.4', require: false  # Faster boot times
gem 'image_processing', '~> 1.2'  # Image processing

# Validation & serialization
gem 'dry-validation'  # Input validation
gem 'fast_jsonapi'  # JSON serialization

# Development and test gems
group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
end

group :development do
  gem 'listen', '~> 3.3'
  gem 'spring'
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
end

group :test do
  gem 'webmock'  # HTTP request stubbing
  gem 'vcr'  # HTTP interaction recording
end

# Monitoring (optional for production)
group :production do
  gem 'sentry-ruby'
  gem 'sentry-rails'
end
