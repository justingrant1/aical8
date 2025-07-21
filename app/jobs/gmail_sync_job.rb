# app/jobs/gmail_sync_job.rb
class GmailSyncJob < ApplicationJob
  queue_as :default
  
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  
  def perform(email_account_id)
    email_account = EmailAccount.find(email_account_id)
    
    Rails.logger.info "Starting Gmail sync for account: #{email_account.email}"
    
    # Update sync status
    email_account.update!(
      sync_status: 'syncing',
      sync_error: nil,
      sync_started_at: Time.current
    )
    
    begin
      # Refresh access token if needed
      refresh_access_token_if_needed(email_account)
      
      # Fetch emails from Gmail API
      emails_synced = sync_emails_from_gmail(email_account)
      
      # Update sync completion
      email_account.update!(
        sync_status: 'completed',
        last_sync_at: Time.current,
        sync_completed_at: Time.current,
        last_sync_email_count: emails_synced
      )
      
      Rails.logger.info "Gmail sync completed for #{email_account.email}. Synced #{emails_synced} emails."
      
      # Queue AI analysis for new emails
      queue_ai_analysis_for_new_emails(email_account)
      
    rescue StandardError => e
      Rails.logger.error "Gmail sync failed for #{email_account.email}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      email_account.update!(
        sync_status: 'failed',
        sync_error: e.message,
        sync_completed_at: Time.current
      )
      
      raise e # Re-raise to trigger retry mechanism
    end
  end
  
  private
  
  def gmail_service
    @gmail_service ||= GmailService.new
  end
  
  def refresh_access_token_if_needed(email_account)
    # Check if token expires within next 5 minutes
    if email_account.token_expires_at && email_account.token_expires_at < 5.minutes.from_now
      Rails.logger.info "Refreshing access token for #{email_account.email}"
      
      refresh_token = decrypt_token(email_account.refresh_token)
      raise "Missing refresh token" unless refresh_token
      
      new_tokens = gmail_service.refresh_access_token(refresh_token)
      
      email_account.update!(
        access_token: encrypt_token(new_tokens['access_token']),
        token_expires_at: Time.current + new_tokens['expires_in'].seconds
      )
      
      # Update refresh token if provided
      if new_tokens['refresh_token']
        email_account.update!(refresh_token: encrypt_token(new_tokens['refresh_token']))
      end
    end
  end
  
  def sync_emails_from_gmail(email_account)
    access_token = decrypt_token(email_account.access_token)
    raise "Missing access token" unless access_token
    
    # Determine sync start date
    sync_since = email_account.last_sync_at || 30.days.ago
    
    # Fetch emails using Gmail API
    gmail_messages = gmail_service.fetch_emails(
      access_token: access_token,
      since: sync_since,
      max_results: 100 # Limit per sync to avoid timeouts
    )
    
    emails_synced = 0
    
    gmail_messages.each do |gmail_message|
      begin
        # Check if email already exists
        existing_email = email_account.emails.find_by(gmail_message_id: gmail_message[:id])
        next if existing_email
        
        # Parse email data
        parsed_email = parse_gmail_message(gmail_message)
        next unless parsed_email
        
        # Save email to database
        email = create_email_record(email_account, gmail_message[:id], parsed_email)
        
        if email
          emails_synced += 1
          Rails.logger.debug "Saved email: #{email.subject}"
        end
        
      rescue StandardError => e
        Rails.logger.error "Failed to process Gmail message #{gmail_message[:id]}: #{e.message}"
        # Continue processing other emails
      end
    end
    
    emails_synced
  end
  
  def parse_gmail_message(gmail_message)
    headers = gmail_message[:payload][:headers] || []
    
    # Extract common headers
    subject = find_header_value(headers, 'Subject') || '(No Subject)'
    from = find_header_value(headers, 'From') || ''
    to = find_header_value(headers, 'To') || ''
    cc = find_header_value(headers, 'Cc')
    bcc = find_header_value(headers, 'Bcc')
    date = find_header_value(headers, 'Date')
    message_id = find_header_value(headers, 'Message-ID') || gmail_message[:id]
    
    # Parse date
    sent_at = parse_email_date(date)
    
    # Extract body content
    body_text, body_html = extract_email_body(gmail_message[:payload])
    
    # Determine email type and importance
    email_type = classify_email_type(subject, body_text, from)
    
    {
      subject: subject,
      sender_email: extract_email_from_address(from),
      sender_name: extract_name_from_address(from),
      recipient_email: extract_email_from_address(to),
      recipient_name: extract_name_from_address(to),
      cc_recipients: cc,
      bcc_recipients: bcc,
      body_text: body_text,
      body_html: body_html,
      sent_at: sent_at,
      message_id: message_id,
      email_type: email_type,
      labels: gmail_message[:labelIds] || [],
      is_read: !gmail_message[:labelIds]&.include?('UNREAD'),
      is_important: gmail_message[:labelIds]&.include?('IMPORTANT'),
      thread_id: gmail_message[:threadId]
    }
  end
  
  def create_email_record(email_account, gmail_message_id, parsed_email)
    Email.create!(
      email_account: email_account,
      organization: email_account.organization,
      gmail_message_id: gmail_message_id,
      gmail_thread_id: parsed_email[:thread_id],
      subject: parsed_email[:subject],
      sender_email: parsed_email[:sender_email],
      sender_name: parsed_email[:sender_name],
      recipient_email: parsed_email[:recipient_email],
      recipient_name: parsed_email[:recipient_name],
      cc_recipients: parsed_email[:cc_recipients],
      bcc_recipients: parsed_email[:bcc_recipients],
      body_text: parsed_email[:body_text],
      body_html: parsed_email[:body_html],
      sent_at: parsed_email[:sent_at],
      email_type: parsed_email[:email_type],
      labels: parsed_email[:labels],
      is_read: parsed_email[:is_read],
      is_important: parsed_email[:is_important],
      raw_headers: parsed_email[:message_id],
      analysis_status: 'pending'
    )
  end
  
  def queue_ai_analysis_for_new_emails(email_account)
    # Find emails that need AI analysis
    pending_emails = email_account.emails
                                 .where(analysis_status: 'pending')
                                 .where('sent_at >= ?', 7.days.ago)
                                 .order(sent_at: :desc)
                                 .limit(20) # Limit to avoid overwhelming the AI service
    
    pending_emails.find_each do |email|
      AiAnalysisJob.perform_later(email.id) if defined?(AiAnalysisJob)
    end
    
    Rails.logger.info "Queued AI analysis for #{pending_emails.count} emails"
  end
  
  # Helper methods
  def find_header_value(headers, name)
    header = headers.find { |h| h[:name].downcase == name.downcase }
    header ? header[:value] : nil
  end
  
  def parse_email_date(date_string)
    return Time.current unless date_string
    
    Time.zone.parse(date_string)
  rescue ArgumentError
    Time.current
  end
  
  def extract_email_body(payload)
    body_text = ''
    body_html = ''
    
    if payload[:body] && payload[:body][:data]
      # Single part message
      body_text = Base64.urlsafe_decode64(payload[:body][:data])
    elsif payload[:parts]
      # Multi-part message
      payload[:parts].each do |part|
        mime_type = part[:mimeType]
        
        if part[:body] && part[:body][:data]
          content = Base64.urlsafe_decode64(part[:body][:data])
          
          if mime_type == 'text/plain'
            body_text += content
          elsif mime_type == 'text/html'
            body_html += content
          end
        end
      end
    end
    
    [body_text, body_html]
  rescue StandardError => e
    Rails.logger.error "Error extracting email body: #{e.message}"
    ['', '']
  end
  
  def extract_email_from_address(address)
    return '' unless address
    
    # Extract email from "Name <email@domain.com>" format
    match = address.match(/<(.+?)>/)
    match ? match[1] : address.split(/\s+/).last
  end
  
  def extract_name_from_address(address)
    return '' unless address
    
    # Extract name from "Name <email@domain.com>" format
    if address.include?('<')
      address.split('<').first.strip.gsub(/^["']|["']$/, '')
    else
      ''
    end
  end
  
  def classify_email_type(subject, body_text, from)
    # Simple email classification based on content
    text_content = "#{subject} #{body_text}".downcase
    
    # Housing authority related
    return 'housing_authority' if text_content.match?(/housing|section\s*8|pha|authority|inspection|voucher/)
    
    # Utility related
    return 'utility' if text_content.match?(/utility|electric|gas|water|sewer|bill|payment/)
    
    # Work order/maintenance
    return 'work_order' if text_content.match?(/work\s*order|repair|maintenance|fix|broken|issue/)
    
    # Payment related
    return 'payment' if text_content.match?(/payment|rent|invoice|bill|due|overdue/)
    
    # Legal/compliance
    return 'legal' if text_content.match?(/legal|court|eviction|notice|violation|complaint/)
    
    # Default
    'general'
  end
  
  def encrypt_token(token)
    return nil unless token
    Rails.application.message_encryptor(:tokens).encrypt_and_sign(token)
  end
  
  def decrypt_token(encrypted_token)
    return nil unless encrypted_token
    Rails.application.message_encryptor(:tokens).decrypt_and_verify(encrypted_token)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage
    Rails.logger.error "Token decryption failed"
    nil
  end
end
