# CalendarAI - Setup Guide

## Quick Start

This guide will help you set up and run the CalendarAI multi-tenant SaaS platform locally.

## Prerequisites

- **Ruby 3.2.0** (use rbenv or rvm to manage versions)
- **PostgreSQL 13+** (with superuser access for development)
- **Redis 6+** (for background jobs with Sidekiq)
- **Node.js 18+** (for future frontend development)
- **Git** for version control

### macOS Installation
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install PostgreSQL and Redis
brew install postgresql@15 redis

# Start services
brew services start postgresql@15
brew services start redis

# Install Ruby version manager
curl -sSL https://get.rvm.io | bash -s stable
rvm install 3.2.0
rvm use 3.2.0 --default
```

### Windows Installation (Native)
```cmd
# Option 1: Using RubyInstaller (Recommended)
# 1. Download Ruby 3.2.0 from https://rubyinstaller.org/
# 2. Download "Ruby+Devkit 3.2.0-1 (x64)" 
# 3. Run the installer and select "Add Ruby executables to your PATH"
# 4. In the final step, select option 3 to install MSYS2 and development toolchain

# Verify Ruby installation
ruby -v
gem -v

# Install PostgreSQL for Windows
# Download from https://www.postgresql.org/download/windows/
# During installation, remember the superuser password

# Install Redis for Windows
# Option A: Using Windows Subsystem for Linux (WSL)
wsl --install Ubuntu-20.04
# Then follow WSL instructions below

# Option B: Using Redis on Windows (Chocolatey)
# Install Chocolatey first: https://chocolatey.org/install
choco install redis-64

# Option C: Docker for Redis
docker run -d -p 6379:6379 redis:latest
```

### Ubuntu/Windows WSL Installation
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install PostgreSQL
sudo apt install postgresql postgresql-contrib

# Install Redis
sudo apt install redis-server

# Install RVM and Ruby
curl -sSL https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
rvm install 3.2.0
rvm use 3.2.0 --default
```

### Windows-Specific Setup Notes
```cmd
# For native Windows development, you may need:

# Install Git for Windows (if not already installed)
# Download from https://git-scm.com/download/win

# Install Node.js (for future frontend development)
# Download from https://nodejs.org/

# Configure PostgreSQL on Windows
# After installation, use pgAdmin or command line:
# Note: Use 'psql -U postgres' instead of 'sudo -u postgres psql'

# Windows PostgreSQL user creation
psql -U postgres
CREATE USER calendarai_dev WITH PASSWORD 'development_password';
ALTER USER calendarai_dev CREATEDB;
\q
```

## Database Setup

### 1. Create PostgreSQL User
```bash
# Connect to PostgreSQL as superuser
sudo -u postgres psql

# Create development user
CREATE USER calendarai_dev WITH PASSWORD 'development_password';
ALTER USER calendarai_dev CREATEDB;
\q
```

### 2. Configure Environment Variables
```bash
# Copy the environment template
cp backend/.env.example backend/.env

# Edit the .env file with your settings
nano backend/.env
```

### 3. Essential Environment Variables
```bash
# Database Configuration
DATABASE_URL=postgresql://calendarai_dev:development_password@localhost:5432/calendarai_development

# Redis Configuration (for Sidekiq)
REDIS_URL=redis://localhost:6379/0

# JWT Secret (generate with: openssl rand -hex 64)
JWT_SECRET=your_generated_jwt_secret_here

# OpenAI API Key (get from https://platform.openai.com/api-keys)
OPENAI_API_KEY=sk-your-openai-api-key-here

# Google OAuth2 Credentials (from Google Cloud Console)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_REDIRECT_URI=http://localhost:3000/auth/callbacks/gmail

# Supabase Configuration (optional for full auth)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key

# Application Configuration
RAILS_ENV=development
FRONTEND_URL=http://localhost:3001
```

## Installation & Setup

### 1. Install Dependencies
```bash
# Navigate to backend directory
cd backend

# Install Ruby gems
bundle install

# Install JavaScript dependencies (if any)
# npm install  # (for future frontend assets)
```

### 2. Database Setup
```bash
# Create and setup databases
rails db:create
rails db:migrate
rails db:seed
```

### 3. Start Services

#### Option A: Individual Services
```bash
# Terminal 1: Start Rails server
rails server

# Terminal 2: Start Sidekiq (background jobs)
bundle exec sidekiq

# Terminal 3: Monitor Redis (optional)
redis-cli monitor
```

#### Option B: Using Foreman (Recommended)
```bash
# Install foreman if not already installed
gem install foreman

# Create Procfile
echo "web: rails server -p 3000" > Procfile
echo "worker: bundle exec sidekiq" >> Procfile
echo "redis: redis-server" >> Procfile

# Start all services
foreman start
```

## Google OAuth2 Setup

### 1. Create Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable Gmail API and Google+ API

### 2. Configure OAuth2 Credentials
1. Go to "Credentials" in the API & Services section
2. Click "Create Credentials" → "OAuth 2.0 Client IDs"
3. Choose "Web application"
4. Add authorized redirect URIs:
   - `http://localhost:3000/auth/callbacks/gmail`
   - `http://localhost:3000/api/v1/gmail/callback`
5. Copy Client ID and Client Secret to your `.env` file

## Testing the Application

### 1. Health Check
```bash
curl http://localhost:3000/health
# Should return: {"status":"ok","timestamp":"..."}
```

### 2. API Endpoints

#### Authentication (Mock for Development)
```bash
# Note: Full authentication requires frontend integration
# For development, you can create test data directly

# Create test organization and user via Rails console
rails console
```

#### Gmail OAuth Flow
```bash
# Get Gmail authorization URL
curl "http://localhost:3000/api/v1/gmail/auth_url" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# List connected Gmail accounts
curl "http://localhost:3000/api/v1/gmail/accounts" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### Dashboard Data
```bash
# Get dashboard analytics
curl "http://localhost:3000/api/v1/dashboard" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Development Workflow

### 1. Database Migrations
```bash
# Generate new migration
rails generate migration AddFieldToModel field:type

# Run migrations
rails db:migrate

# Rollback if needed
rails db:rollback
```

### 2. Background Jobs
```bash
# Monitor Sidekiq jobs
open http://localhost:4567  # Sidekiq Web UI

# Queue a test job
rails console
> GmailSyncJob.perform_later(email_account_id)
```

### 3. Testing
```bash
# Run the test suite
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/organization_spec.rb

# Check test coverage
open coverage/index.html
```

## Troubleshooting

### Common Issues

#### 1. Database Connection Errors
```bash
# Check if PostgreSQL is running
pg_ctl -D /usr/local/var/postgres status

# Start PostgreSQL if stopped
brew services start postgresql@15  # macOS
sudo service postgresql start      # Ubuntu
```

#### 2. Redis Connection Errors
```bash
# Check if Redis is running
redis-cli ping  # Should return "PONG"

# Start Redis if stopped
brew services start redis  # macOS
sudo service redis start   # Ubuntu
```

#### 3. Gem Installation Issues
```bash
# Clear bundle cache and reinstall
bundle clean --force
bundle install

# If pg gem fails to install
bundle config build.pg --with-pg-config=/usr/local/bin/pg_config
bundle install
```

#### 4. Permission Errors
```bash
# Fix file permissions
chmod -R 755 .
chown -R $USER:$USER .
```

### Logs and Debugging

```bash
# View Rails logs
tail -f log/development.log

# View Sidekiq logs
tail -f log/sidekiq.log

# Rails console for debugging
rails console

# Database console
rails dbconsole
```

## Production Deployment Preparation

### 1. Environment Setup
- Set `RAILS_ENV=production`
- Use secure, random values for all secrets
- Configure proper database and Redis URLs
- Set up SSL certificates

### 2. Database Configuration
```bash
# Production database setup
RAILS_ENV=production rails db:create db:migrate
```

### 3. Asset Compilation
```bash
# Precompile assets for production
RAILS_ENV=production rails assets:precompile
```

### 4. Security Checklist
- [ ] Change all default passwords and secrets
- [ ] Enable database SSL connections
- [ ] Configure CORS for production domains only
- [ ] Set up proper logging and monitoring
- [ ] Configure backup strategies

## Next Steps

Once you have the backend running successfully:

1. **Test the core functionality** using the provided API endpoints
2. **Set up a frontend** (React/Next.js recommended)
3. **Configure monitoring** and alerting systems
4. **Set up CI/CD** pipelines for automated deployment
5. **Implement advanced features** like webhooks and custom workflows

## Support

For issues or questions:
- Check the logs first: `tail -f log/development.log`
- Review the database schema: `rails db:schema:dump`
- Use Rails console for debugging: `rails console`
- Review the project status: `PROJECT_STATUS.md`

## Architecture Overview

The application is built as a multi-tenant SaaS platform with:
- **Organizations** as the primary tenant separator
- **Complete data isolation** between customers
- **Role-based access control** within organizations
- **Background job processing** for email sync and AI analysis
- **RESTful API** design for frontend integration
- **Comprehensive error handling** and logging

Happy coding! 🚀
