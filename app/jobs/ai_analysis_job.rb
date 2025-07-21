# app/jobs/ai_analysis_job.rb
class AiAnalysisJob < ApplicationJob
  queue_as :default
  
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  
  def perform(email_id)
    email = Email.find(email_id)
    
    Rails.logger.info "Starting AI analysis for email: #{email.id} - #{email.subject}"
    
    # Update analysis status
    email.update!(analysis_status: 'analyzing')
    
    begin
      # Run AI analysis
      analysis_result = ai_analysis_service.analyze_email(email)
      
      # Save analysis results
      save_analysis_results(email, analysis_result)
      
      # Create tasks if needed
      create_tasks_from_analysis(email, analysis_result)
      
      # Update completion status
      email.update!(
        analysis_status: 'completed',
        analyzed_at: Time.current
      )
      
      Rails.logger.info "AI analysis completed for email: #{email.id}"
      
    rescue StandardError => e
      Rails.logger.error "AI analysis failed for email #{email.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      email.update!(
        analysis_status: 'failed',
        analysis_error: e.message,
        analyzed_at: Time.current
      )
      
      raise e # Re-raise to trigger retry mechanism
    end
  end
  
  private
  
  def ai_analysis_service
    @ai_analysis_service ||= AiAnalysisService.new
  end
  
  def save_analysis_results(email, analysis_result)
    # Create AI analysis log entry
    AiAnalysisLog.create!(
      email: email,
      organization: email.organization,
      email_account: email.email_account,
      analysis_type: 'email_content',
      input_data: {
        subject: email.subject,
        body_preview: email.body_text&.truncate(500),
        sender: email.sender_email,
        email_type: email.email_type
      },
      analysis_results: analysis_result,
      confidence_score: analysis_result['confidence_score'] || 0.0,
      processing_time_ms: analysis_result['processing_time_ms'] || 0,
      tokens_used: analysis_result['tokens_used'] || 0,
      model_version: analysis_result['model_version'] || 'unknown'
    )
    
    # Update email with extracted information
    update_email_with_analysis(email, analysis_result)
  end
  
  def update_email_with_analysis(email, analysis_result)
    updates = {}
    
    # Extract key information from analysis
    if analysis_result['key_information']
      key_info = analysis_result['key_information']
      
      updates[:ai_extracted_data] = {
        'property_address' => key_info['property_address'],
        'tenant_name' => key_info['tenant_name'],
        'property_id' => key_info['property_id'],
        'unit_number' => key_info['unit_number'],
        'inspection_date' => key_info['inspection_date'],
        'work_order_number' => key_info['work_order_number'],
        'amount_due' => key_info['amount_due'],
        'due_date' => key_info['due_date'],
        'priority_level' => key_info['priority_level'],
        'contact_info' => key_info['contact_info']
      }
    end
    
    # Update priority based on AI analysis
    if analysis_result['priority']
      updates[:priority] = analysis_result['priority']
    end
    
    # Update email type if AI determined a more specific type
    if analysis_result['email_type'] && analysis_result['email_type'] != email.email_type
      updates[:email_type] = analysis_result['email_type']
    end
    
    # Update requires action flag
    if analysis_result['requires_action']
      updates[:requires_action] = analysis_result['requires_action']
    end
    
    # Update action deadline if identified
    if analysis_result['action_deadline']
      updates[:action_deadline] = parse_date(analysis_result['action_deadline'])
    end
    
    email.update!(updates) if updates.any?
  end
  
  def create_tasks_from_analysis(email, analysis_result)
    return unless analysis_result['suggested_tasks']&.any?
    
    analysis_result['suggested_tasks'].each do |task_data|
      begin
        create_task_from_suggestion(email, task_data)
      rescue StandardError => e
        Rails.logger.error "Failed to create task from AI suggestion: #{e.message}"
        # Continue with other tasks
      end
    end
  end
  
  def create_task_from_suggestion(email, task_data)
    # Find associated property if possible
    property = find_associated_property(email, task_data)
    
    # Determine task priority
    priority = map_ai_priority_to_task_priority(task_data['priority'])
    
    # Set due date
    due_date = parse_due_date(task_data['due_date']) || determine_default_due_date(task_data['task_type'])
    
    task = Task.create!(
      organization: email.organization,
      property: property,
      email: email,
      title: task_data['title'],
      description: task_data['description'] || build_task_description(email, task_data),
      task_type: task_data['task_type'] || 'general',
      priority: priority,
      status: 'pending',
      due_date: due_date,
      source: 'ai_analysis',
      created_by_ai: true,
      ai_confidence_score: task_data['confidence'] || 0.0,
      metadata: {
        'email_id' => email.id,
        'ai_analysis_id' => email.ai_analysis_logs.last&.id,
        'extracted_data' => task_data['extracted_data'],
        'suggested_assignee' => task_data['suggested_assignee']
      }
    )
    
    Rails.logger.info "Created AI-suggested task: #{task.id} - #{task.title}"
    
    # TODO: Notify relevant users about new task
    # NotificationJob.perform_later(task.id, 'task_created')
    
    task
  end
  
  def find_associated_property(email, task_data)
    # Try to find property by extracted data
    if task_data['extracted_data']
      data = task_data['extracted_data']
      
      # Try by property ID first
      if data['property_id']
        property = email.organization.properties.find_by(property_id: data['property_id'])
        return property if property
      end
      
      # Try by address
      if data['property_address']
        property = email.organization.properties.where(
          "LOWER(street_address) LIKE LOWER(?)", 
          "%#{data['property_address'].downcase}%"
        ).first
        return property if property
      end
      
      # Try by unit number and partial address match
      if data['unit_number'] && data['property_address']
        property = email.organization.properties.where(
          "unit_number = ? AND LOWER(street_address) LIKE LOWER(?)",
          data['unit_number'],
          "%#{data['property_address'].split.first}%"
        ).first
        return property if property
      end
    end
    
    # If no property found, try to match from email AI extracted data
    if email.ai_extracted_data
      # Similar logic for email's extracted data
      # This allows fallback if task suggestion doesn't have complete data
    end
    
    nil # No property found
  end
  
  def map_ai_priority_to_task_priority(ai_priority)
    case ai_priority&.downcase
    when 'critical', 'urgent', 'high'
      'high'
    when 'medium', 'normal'
      'medium'
    when 'low', 'minor'
      'low'
    else
      'medium' # Default
    end
  end
  
  def determine_default_due_date(task_type)
    case task_type&.downcase
    when 'inspection'
      # Inspections typically have 24-48 hours notice
      2.days.from_now
    when 'work_order', 'maintenance'
      # Maintenance requests usually 3-5 business days
      5.business_days.from_now
    when 'payment', 'invoice'
      # Payment issues usually need quick attention
      1.business_day.from_now
    when 'compliance', 'legal'
      # Legal matters need immediate attention
      1.business_day.from_now
    when 'certification', 'renewal'
      # Certifications usually have more time
      14.days.from_now
    else
      # Default to 3 business days
      3.business_days.from_now
    end
  end
  
  def build_task_description(email, task_data)
    description = "Task created from email analysis\n\n"
    description += "**Email Subject:** #{email.subject}\n"
    description += "**From:** #{email.sender_email}\n"
    description += "**Date:** #{email.sent_at.strftime('%Y-%m-%d %H:%M')}\n\n"
    
    if task_data['key_points']
      description += "**Key Points:**\n"
      task_data['key_points'].each do |point|
        description += "• #{point}\n"
      end
      description += "\n"
    end
    
    if task_data['extracted_data']&.any?
      description += "**Extracted Information:**\n"
      task_data['extracted_data'].each do |key, value|
        next unless value
        formatted_key = key.humanize
        description += "• #{formatted_key}: #{value}\n"
      end
      description += "\n"
    end
    
    description += "**Email Preview:**\n"
    description += email.body_text&.truncate(300) || "No text content available"
    
    description
  end
  
  def parse_date(date_string)
    return nil unless date_string
    
    # Try various date formats
    [
      '%Y-%m-%d',
      '%m/%d/%Y',
      '%d/%m/%Y',
      '%Y-%m-%d %H:%M:%S',
      '%m/%d/%Y %H:%M:%S'
    ].each do |format|
      begin
        return Date.strptime(date_string, format)
      rescue ArgumentError
        # Try next format
      end
    end
    
    # Try natural language parsing
    begin
      return Date.parse(date_string)
    rescue ArgumentError
      Rails.logger.warn "Could not parse date: #{date_string}"
      nil
    end
  end
  
  def parse_due_date(date_string)
    parse_date(date_string)
  end
end
