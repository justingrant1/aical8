# Multi-Tenant SaaS Email Analysis System

A sophisticated Rails API-based SaaS platform for property management companies to automatically analyze Gmail emails, extract actionable tasks, and manage Section 8 rental properties with AI-powered insights.

## 🎯 Overview

This system provides property managers with intelligent email analysis, automatic task generation, and comprehensive property management tools specifically designed for Section 8 housing workflows.

### Key Features
- **Multi-tenant SaaS architecture** with complete data isolation
- **Gmail integration** with OAuth2 and real-time email monitoring
- **AI-powered email analysis** using OpenAI GPT-4o-mini
- **Automated task creation** from emails with Section 8 context
- **Property management** with occupancy and inspection tracking
- **Dashboard analytics** with critical items and deadline tracking
- **Section 8 specialized workflows** (housing authorities, inspections, utilities)

## 🏗️ Architecture

### Multi-Tenant Design
- Organizations (customers) have complete data isolation
- User profiles with role-based permissions (admin, manager, viewer)
- Subscription management with usage tracking
- API rate limiting per customer

### Core Components
- **Rails API backend** with PostgreSQL database
- **Supabase authentication** with JWT tokens
- **Gmail API integration** for email processing
- **OpenAI API** for intelligent email analysis
- **Background job processing** for email analysis
- **RESTful API** with comprehensive endpoints

## 🚀 Quick Start

### Prerequisites
- Ruby 3.1+ 
- PostgreSQL 12+
- Redis (for background jobs)
- Node.js 16+ (for any frontend development)

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd calendarai/backend
```

2. **Install dependencies**
```bash
bundle install
```

3. **Database setup**
```bash
# Create and setup database
rails db:create
rails db:migrate
rails db:seed

# This will create demo data including:
# - Demo organization with properties
# - Sample housing authorities (SF, NYC, LA)
# - Utility companies (PG&E, ConEd, LADWP, SoCal Gas)
```

4. **Environment configuration**
```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your actual credentials:
# - Database connection
# - OpenAI API key
# - Google OAuth credentials  
# - Supabase configuration
```

5. **Start the server**
```bash
rails server
# API will be available at http://localhost:3000
```

## 🔧 Configuration

### Required Environment Variables

#### Database
```
DATABASE_URL=postgresql://username:password@localhost:5432/section8_rental_manager_development
```

#### API Keys
```
OPENAI_API_KEY=sk-your-openai-api-key-here
GOOGLE_CLIENT_ID=your-google-oauth-client-id
GOOGLE_CLIENT_SECRET=your-google-oauth-client-secret
```

#### Supabase Authentication
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key
```

### Optional Configuration
- Frontend URL for CORS
- Redis URL for production caching
- SMTP settings for email notifications
- Feature flags for AI analysis and auto-task creation

## 📊 Database Schema

### Core Models
- **Organization** - Multi-tenant customer isolation
- **UserProfile** - User management with Supabase integration
- **Property** - Rental property management with Section 8 details
- **EmailAccount** - Gmail OAuth credential storage per customer
- **Email** - Email storage with AI analysis results
- **Task** - Automated task generation from emails
- **AiAnalysisLog** - AI processing tracking and cost analysis

### Section 8 Specialized
- **HousingAuthority** - Housing authority recognition and contact info
- **Utility** - Utility company detection for bill processing

## 🤖 AI Analysis Features

### Email Classification
- `inspection_confirmation` - HQS/Annual/Re-inspections
- `utility_bill` - Power, water, gas bills with due date extraction
- `work_order_update` - Maintenance completion notices
- `rfta_completion` - Request for Tenant Action completions
- `rental_increase` - Rent increase notifications
- `tenant_communication` & `contractor_communication`

### Automatic Task Generation
- Inspection preparation tasks with housing authority detection
- Utility payment tasks with due date and amount extraction
- Work order follow-up tasks
- RFTA verification tasks

### Intelligence Features
- Property matching using address extraction
- Priority analysis with Section 8 urgency factors
- Entity detection (housing authorities, utility companies)
- Confidence scoring for all AI decisions

## 📚 API Endpoints

### Authentication
- `POST /api/v1/auth/login` - User login with Supabase JWT
- `POST /api/v1/auth/refresh` - Token refresh

### Dashboard
- `GET /api/v1/dashboard` - Main dashboard with key metrics

### Properties
- `GET /api/v1/properties` - List properties with filters
- `POST /api/v1/properties` - Create new property
- `GET /api/v1/properties/:id` - Get property details
- `PUT /api/v1/properties/:id` - Update property

### Tasks
- `GET /api/v1/tasks` - List tasks with filters
- `POST /api/v1/tasks` - Create task
- `PUT /api/v1/tasks/:id` - Update task status

### Emails
- `GET /api/v1/emails` - List processed emails
- `GET /api/v1/emails/:id` - Get email details
- `POST /api/v1/emails/analyze` - Trigger email analysis

### Gmail Integration
- `POST /api/v1/gmail/connect` - Connect Gmail account
- `GET /api/v1/gmail/sync` - Trigger email sync
- `GET /api/v1/gmail/status` - Check sync status

## 🔐 Security

### Authentication & Authorization
- JWT token-based authentication via Supabase
- Role-based access control (admin, manager, viewer)
- Multi-tenant data isolation at database level
- API rate limiting per organization

### Data Protection
- Encrypted OAuth token storage
- Secure credential management
- CORS protection for frontend integration
- SQL injection prevention via ActiveRecord

## 🚀 Deployment

### Environment Setup
1. Set all required environment variables
2. Configure database with production credentials
3. Set up Redis for caching and background jobs
4. Configure SMTP for email notifications

### Database Migration
```bash
RAILS_ENV=production rails db:create
RAILS_ENV=production rails db:migrate
```

### Background Jobs
Configure Sidekiq or similar for background email processing:
```bash
bundle exec sidekiq
```

## 🧪 Development

### Running Tests
```bash
# Install test dependencies
bundle install

# Run test suite
rails test
```

### API Testing
The system includes comprehensive seed data for testing:
- Demo organization: "Demo Property Management"
- Sample properties with Section 8 details
- Pre-configured housing authorities and utilities

### Database Console
```bash
rails console
# Access all models and test data relationships
```

## 📈 Monitoring & Analytics

### Usage Tracking
- Email processing volume per customer
- AI analysis costs and token usage
- Task completion rates
- Property management metrics

### Performance Metrics
- API response times
- Background job processing
- Database query optimization
- AI analysis confidence scores

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is proprietary software developed for SaaS deployment.

## 🆘 Support

For development questions or deployment support, please create an issue with detailed information about your setup and the problem you're experiencing.

---

**Ready for SaaS deployment!** This foundation provides a complete, scalable backend for a multi-tenant property management platform with intelligent email analysis.
