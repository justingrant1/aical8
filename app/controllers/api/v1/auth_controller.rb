# app/controllers/api/v1/auth_controller.rb
class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:login, :refresh]

  # POST /api/v1/auth/login
  # Login with Supabase JWT token
  def login
    begin
      # Extract token from Authorization header
      token = extract_token_from_header
      return render_error('Missing authorization token', :unauthorized) unless token

      # Verify token with Supabase
      user_data = verify_supabase_token(token)
      return render_error('Invalid token', :unauthorized) unless user_data

      # Find or create user profile
      user_profile = find_or_create_user_profile(user_data, token)
      
      if user_profile
        # Generate session token or use existing
        render json: {
          success: true,
          user: user_profile_response(user_profile),
          organization: organization_response(user_profile.organization),
          token: token # Return the same token for frontend storage
        }
      else
        render_error('Failed to create user profile', :unprocessable_entity)
      end

    rescue StandardError => e
      Rails.logger.error "Auth login error: #{e.message}"
      render_error('Authentication failed', :unauthorized)
    end
  end

  # POST /api/v1/auth/refresh
  # Refresh JWT token
  def refresh
    begin
      token = extract_token_from_header
      return render_error('Missing authorization token', :unauthorized) unless token

      # Verify current token is still valid or can be refreshed
      user_data = verify_supabase_token(token)
      
      if user_data
        user_profile = UserProfile.find_by(supabase_user_id: user_data['sub'])
        
        if user_profile
          render json: {
            success: true,
            user: user_profile_response(user_profile),
            organization: organization_response(user_profile.organization),
            token: token
          }
        else
          render_error('User profile not found', :not_found)
        end
      else
        render_error('Token refresh failed', :unauthorized)
      end

    rescue StandardError => e
      Rails.logger.error "Auth refresh error: #{e.message}"
      render_error('Token refresh failed', :unauthorized)
    end
  end

  # POST /api/v1/auth/logout
  # Logout user (mainly for cleanup)
  def logout
    # In JWT stateless auth, logout is mainly client-side
    # Could add token blacklisting here if needed
    render json: { success: true, message: 'Logged out successfully' }
  end

  private

  def extract_token_from_header
    auth_header = request.headers['Authorization']
    return nil unless auth_header&.start_with?('Bearer ')
    
    auth_header.split(' ').last
  end

  def verify_supabase_token(token)
    # This would typically verify the JWT token with Supabase
    # For now, we'll decode without verification for development
    # In production, you'd verify the signature with Supabase's public key
    
    begin
      # Simple JWT decode (in production, add signature verification)
      decoded = JWT.decode(token, nil, false) # false = no verification for dev
      decoded[0] # Return the payload
    rescue JWT::DecodeError => e
      Rails.logger.error "JWT decode error: #{e.message}"
      nil
    end
  end

  def find_or_create_user_profile(user_data, token)
    supabase_user_id = user_data['sub']
    email = user_data['email']
    
    user_profile = UserProfile.find_by(supabase_user_id: supabase_user_id)
    
    unless user_profile
      # For new users, we need to determine which organization they belong to
      # This could be based on email domain, invitation, or manual assignment
      organization = find_or_create_organization_for_user(email, user_data)
      
      user_profile = UserProfile.create!(
        organization: organization,
        supabase_user_id: supabase_user_id,
        email: email,
        first_name: user_data['user_metadata']&.dig('first_name') || extract_first_name(email),
        last_name: user_data['user_metadata']&.dig('last_name') || '',
        role: determine_user_role(email, organization),
        phone_number: user_data['user_metadata']&.dig('phone_number'),
        preferences: default_user_preferences
      )
    end
    
    # Update last login
    user_profile.update_column(:updated_at, Time.current)
    
    user_profile
  end

  def find_or_create_organization_for_user(email, user_data)
    # For demo, assign to demo organization
    # In production, this would be based on invitation system or email domain matching
    demo_org = Organization.find_by(slug: 'demo-properties')
    return demo_org if demo_org

    # Create new organization if none exists (for first user)
    domain = email.split('@').last
    org_name = user_data['user_metadata']&.dig('company_name') || "#{domain.split('.').first.capitalize} Properties"
    
    Organization.create!(
      name: org_name,
      slug: generate_org_slug(org_name),
      contact_email: email,
      subscription_status: 'trial',
      subscription_tier: 'basic',
      subscription_expires_at: 30.days.from_now,
      settings: default_organization_settings
    )
  end

  def determine_user_role(email, organization)
    # First user in organization becomes admin
    return 'admin' if organization.user_profiles.count == 0
    
    # Otherwise, default to viewer (admin can upgrade later)
    'viewer'
  end

  def generate_org_slug(name)
    base_slug = name.downcase.gsub(/[^a-z0-9\s]/, '').gsub(/\s+/, '-')
    counter = 1
    slug = base_slug
    
    while Organization.exists?(slug: slug)
      slug = "#{base_slug}-#{counter}"
      counter += 1
    end
    
    slug
  end

  def extract_first_name(email)
    email.split('@').first.split('.').first.capitalize
  end

  def default_user_preferences
    {
      'dashboard_layout' => 'standard',
      'email_frequency' => 'daily',
      'time_zone' => 'America/New_York',
      'notifications_enabled' => true
    }
  end

  def default_organization_settings
    {
      'ai_analysis_enabled' => true,
      'auto_task_creation' => true,
      'email_notifications' => true,
      'max_properties' => 10, # Trial limit
      'max_users' => 3        # Trial limit
    }
  end

  def user_profile_response(user_profile)
    {
      id: user_profile.id,
      email: user_profile.email,
      first_name: user_profile.first_name,
      last_name: user_profile.last_name,
      role: user_profile.role,
      phone_number: user_profile.phone_number,
      preferences: user_profile.preferences,
      created_at: user_profile.created_at,
      updated_at: user_profile.updated_at
    }
  end

  def organization_response(organization)
    {
      id: organization.id,
      name: organization.name,
      slug: organization.slug,
      subscription_status: organization.subscription_status,
      subscription_tier: organization.subscription_tier,
      subscription_expires_at: organization.subscription_expires_at,
      settings: organization.settings,
      contact_email: organization.contact_email
    }
  end
end
