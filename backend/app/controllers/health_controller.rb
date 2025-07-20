class HealthController < ApplicationController
  def check
    render json: { 
      status: 'ok', 
      timestamp: Time.current,
      environment: Rails.env,
      database: database_status,
      version: '1.0.0'
    }
  end

  private

  def database_status
    ActiveRecord::Base.connection.execute('SELECT 1')
    'connected'
  rescue StandardError => e
    Rails.logger.error "Database health check failed: #{e.message}"
    'disconnected'
  end
end
