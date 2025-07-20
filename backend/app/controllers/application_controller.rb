class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate_user!
  before_action :set_current_organization
  before_action :ensure_active_subscription

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  rescue_from StandardError, with: :internal_server_error

  protected

  # Authentication using Supabase JWT tokens
  def authenticate_user!
    token = extract_token_from_header
    
    if token.blank?
      render json: { error: 'Access token required' }, status: :unauthorized
      return
    end

    begin
      @current_user = decode_supabase_token(token)
    rescue JWT::DecodeError => e
      render json: { error: 'Invalid token' }, status: :unauthorized
      return
    end
  end

  def current_user
    @current_user
  end

  def current_user_profile
    @current_user_profile ||= UserProfile.find_by(id: current_user['sub']) if current_user
  end

  def set_current_organization
    @current_organization = current_user_profile&.organization
    
    if @current_organization.nil?
      render json: { error: 'Organization not found' }, status: :forbidden
      return
    end
  end

  def current_organization
    @current_organization
  end

  def ensure_active_subscription
    return if current_organization&.active_subscription?
    
    render json: { 
      error: 'Subscription required',
      subscription_status: current_organization&.subscription_status
    }, status: :payment_required
  end

  # Authorization helpers
  def require_admin!
    return if current_user_profile&.admin?
    render json: { error: 'Admin access required' }, status: :forbidden
  end

  def require_manager!
    return if current_user_profile&.can_manage_properties?
    render json: { error: 'Manager access required' }, status: :forbidden
  end

  def can_manage_email_accounts?
    current_user_profile&.can_manage_email_accounts?
  end

  # Pagination helpers
  def paginate(relation)
    page = params[:page]&.to_i || 1
    per_page = [params[:per_page]&.to_i || 25, 100].min # Max 100 per page
    
    relation.offset((page - 1) * per_page).limit(per_page)
  end

  def pagination_meta(relation, paginated_relation)
    total = relation.respond_to?(:count) ? relation.count : relation.size
    page = params[:page]&.to_i || 1
    per_page = paginated_relation.limit_value || 25
    
    {
      current_page: page,
      per_page: per_page,
      total_pages: (total.to_f / per_page).ceil,
      total_count: total
    }
  end

  private

  def extract_token_from_header
    authenticate_with_http_token { |token, _| token }
  end

  def decode_supabase_token(token)
    # TODO: Implement proper Supabase JWT verification
    # This should verify the token signature using Supabase's public key
    # For now, we'll decode without verification (NOT PRODUCTION READY)
    JWT.decode(token, nil, false)[0]
  end

  # Error handling
  def not_found(exception)
    render json: { 
      error: 'Resource not found',
      message: exception.message 
    }, status: :not_found
  end

  def unprocessable_entity(exception)
    render json: { 
      error: 'Validation failed',
      details: exception.record.errors.full_messages 
    }, status: :unprocessable_entity
  end

  def internal_server_error(exception)
    Rails.logger.error "Internal Server Error: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    
    render json: { 
      error: 'Internal server error' 
    }, status: :internal_server_error
  end
end
