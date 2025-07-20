# Database Schema Overview

## Multi-Tenant Architecture

Our database uses a single PostgreSQL database with Row-Level Security (RLS) for multi-tenancy. All tenant-specific data is isolated by `organization_id`.

## Core Tables

### organizations
- **Purpose**: Root tenant table, each customer is an organization
- **Key Fields**: name, subdomain, subscription_status, subscription_tier
- **RLS**: Users can only see their own organization

### user_profiles  
- **Purpose**: Extends Supabase auth.users with organization membership and roles
- **Key Fields**: organization_id, role (admin/manager/viewer), profile info
- **RLS**: Users can see profiles in their organization only

### properties
- **Purpose**: Rental properties managed by each organization
- **Key Fields**: address, property details, tenant info, lease dates, status
- **RLS**: Organization-scoped access

### email_accounts
- **Purpose**: Gmail OAuth connections per organization
- **Key Fields**: email_address, encrypted tokens, sync settings
- **RLS**: Admin-only access within organization

### emails
- **Purpose**: Processed email metadata and AI analysis results
- **Key Fields**: gmail IDs, sender/recipient, AI category, priority, confidence
- **RLS**: Organization-scoped access

### tasks
- **Purpose**: Automated and manual task management
- **Key Fields**: title, type, status, priority, due_date, property_id, email_id
- **RLS**: Users see all org tasks, can update assigned/created tasks

### ai_analysis_logs
- **Purpose**: Detailed AI processing logs for learning and debugging
- **Key Fields**: analysis_type, input/output data, confidence, costs, feedback
- **RLS**: Organization-scoped access

## Security Features

- **Row-Level Security**: All tables have RLS policies for data isolation
- **Role-Based Access**: Admin, Manager, Viewer roles with different permissions
- **Encrypted Credentials**: OAuth tokens encrypted at rest
- **Audit Trail**: AI analysis and user actions logged

## Performance Optimizations

- **Indexes**: Strategic indexes on organization_id and frequently queried fields
- **Automatic Timestamps**: updated_at triggers on relevant tables
- **Efficient Queries**: RLS policies designed for index usage

## Next Steps

1. Set up Rails API backend with Supabase integration
2. Implement Gmail OAuth flow
3. Build AI email analysis pipeline
4. Create React dashboard frontend
