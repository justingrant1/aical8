class AiAnalysisService
  include HTTParty
  base_uri 'https://api.openai.com'

  def initialize(organization)
    @organization = organization
    @api_key = Rails.application.config.openai_api_key
  end

  # Main method to analyze an email and extract actionable information
  def analyze_email(email)
    return unless @api_key

    analysis_log = create_analysis_log(email, 'email_categorization')
    
    begin
      analysis_log.update!(status: 'processing', started_at: Time.current)
      
      # First, try basic categorization using our built-in rules
      email.categorize_automatically
      
      # Perform multiple AI analysis tasks
      categorization_result = categorize_email(email)
      task_extraction_result = extract_section8_tasks(email)
      property_matching_result = match_property_enhanced(email)
      priority_analysis_result = analyze_priority(email)
      section8_analysis_result = analyze_section8_specifics(email)
      
      # Combine results
      combined_results = {
        category: categorization_result[:category],
        confidence_score: calculate_overall_confidence([
          categorization_result[:confidence],
          task_extraction_result[:confidence],
          property_matching_result[:confidence],
          priority_analysis_result[:confidence]
        ]),
        priority_level: priority_analysis_result[:priority],
        suggested_tasks: task_extraction_result[:tasks],
        matched_property: property_matching_result[:property],
        extracted_data: {
          categorization: categorization_result,
          tasks: task_extraction_result,
          property: property_matching_result,
          priority: priority_analysis_result
        }
      }
      
      # Update email with AI results
      update_email_with_results(email, combined_results)
      
      # Create tasks if confidence is high enough
      auto_create_tasks(email, combined_results) if should_auto_create_tasks?(combined_results)
      
      # Log successful analysis
      analysis_log.update!(
        status: 'completed',
        completed_at: Time.current,
        output_data: combined_results.to_json,
        confidence_score: combined_results[:confidence_score],
        processing_cost: calculate_processing_cost(email)
      )
      
      combined_results
      
    rescue => e
      Rails.logger.error "AI Analysis failed for email #{email.id}: #{e.message}"
      analysis_log.update!(
        status: 'failed',
        completed_at: Time.current,
        error_message: e.message
      )
      nil
    end
  end

  # Categorize email into predefined categories
  def categorize_email(email)
    prompt = build_categorization_prompt(email)
    
    response = call_openai_api(prompt, temperature: 0.1, max_tokens: 100)
    
    if response
      parse_categorization_response(response)
    else
      { category: 'unknown', confidence: 0.0, reasoning: 'API call failed' }
    end
  end

  # Extract potential tasks from email content
  def extract_tasks(email)
    prompt = build_task_extraction_prompt(email)
    
    response = call_openai_api(prompt, temperature: 0.2, max_tokens: 500)
    
    if response
      parse_task_extraction_response(response)
    else
      { tasks: [], confidence: 0.0, reasoning: 'API call failed' }
    end
  end

  # Try to match email content to existing properties
  def match_property(email)
    properties = @organization.properties.includes(:tasks)
    prompt = build_property_matching_prompt(email, properties)
    
    response = call_openai_api(prompt, temperature: 0.1, max_tokens: 200)
    
    if response
      parse_property_matching_response(response, properties)
    else
      { property: nil, confidence: 0.0, reasoning: 'API call failed' }
    end
  end

  # Analyze email priority and urgency
  def analyze_priority(email)
    prompt = build_priority_analysis_prompt(email)
    
    response = call_openai_api(prompt, temperature: 0.1, max_tokens: 150)
    
    if response
      parse_priority_response(response)
    else
      { priority: 'normal', confidence: 0.0, reasoning: 'API call failed' }
    end
  end

  private

  def call_openai_api(prompt, temperature: 0.3, max_tokens: 300)
    response = self.class.post('/v1/chat/completions', {
      headers: {
        'Authorization' => "Bearer #{@api_key}",
        'Content-Type' => 'application/json'
      },
      body: {
        model: 'gpt-4o-mini', # Cost-effective model
        messages: [
          {
            role: 'system',
            content: 'You are an AI assistant specialized in property management and rental operations. Analyze emails and extract actionable information.'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        temperature: temperature,
        max_tokens: max_tokens,
        response_format: { type: 'json_object' }
      }.to_json
    })

    if response.success?
      data = JSON.parse(response.body)
      content = data.dig('choices', 0, 'message', 'content')
      JSON.parse(content) if content
    else
      Rails.logger.error "OpenAI API Error: #{response.body}"
      nil
    end
  end

  def build_categorization_prompt(email)
    categories = %w[inspection_confirmation utility_bill work_order_update tenant_communication 
                   rfta_completion rental_increase contractor_communication other]
    
    <<~PROMPT
      Analyze this email and categorize it. Return JSON in this format:
      {
        "category": "category_name",
        "confidence": 0.85,
        "reasoning": "Brief explanation"
      }

      Available categories: #{categories.join(', ')}

      Email Details:
      Subject: #{email.subject}
      From: #{email.sender_display_name}
      Preview: #{email.body_preview}
      
      Consider:
      - Subject line keywords
      - Sender type (tenant, vendor, management company, etc.)
      - Content context and urgency indicators
    PROMPT
  end

  def build_task_extraction_prompt(email)
    task_types = %w[maintenance inspection compliance leasing financial other]
    priorities = %w[low normal high urgent]
    
    <<~PROMPT
      Analyze this email and extract any actionable tasks. Return JSON in this format:
      {
        "tasks": [
          {
            "title": "Task title",
            "description": "Detailed description",
            "task_type": "maintenance",
            "priority": "high",
            "suggested_due_date": "2024-01-15",
            "confidence": 0.9,
            "reasoning": "Why this task was identified"
          }
        ],
        "confidence": 0.85,
        "reasoning": "Overall assessment"
      }

      Email Details:
      Subject: #{email.subject}
      From: #{email.sender_display_name}
      Content Preview: #{email.body_preview}
      
      Task Types: #{task_types.join(', ')}
      Priorities: #{priorities.join(', ')}
      
      Look for:
      - Action items or requests
      - Deadlines or time-sensitive matters
      - Maintenance issues
      - Compliance requirements
      - Financial obligations
    PROMPT
  end

  def build_property_matching_prompt(email, properties)
    property_info = properties.limit(10).map do |p|
      "ID: #{p.id}, Address: #{p.full_address}"
    end.join("\n")
    
    <<~PROMPT
      Match this email to a specific property if possible. Return JSON in this format:
      {
        "property_id": 123,
        "confidence": 0.8,
        "reasoning": "Address mentioned in email matches property",
        "matched_text": "Text from email that indicates the property"
      }

      Email Details:
      Subject: #{email.subject}
      From: #{email.sender_display_name}
      Content Preview: #{email.body_preview}
      
      Available Properties:
      #{property_info}
      
      Look for:
      - Specific addresses mentioned
      - Unit numbers
      - Property references
      - Tenant names that might match property records
      
      Return property_id as null if no clear match found.
    PROMPT
  end

  def build_priority_analysis_prompt(email)
    <<~PROMPT
      Analyze this email's urgency and priority level. Return JSON in this format:
      {
        "priority": "high",
        "confidence": 0.9,
        "reasoning": "Emergency maintenance request with safety concerns",
        "urgency_indicators": ["emergency", "urgent", "safety"]
      }

      Email Details:
      Subject: #{email.subject}
      From: #{email.sender_display_name}
      Content Preview: #{email.body_preview}
      Received: #{email.received_at}
      
      Priority Levels:
      - urgent: Immediate attention required (safety, emergencies, legal deadlines)
      - high: Important, should be handled within 24-48 hours
      - normal: Standard business priority
      - low: Can be handled when convenient
      
      Consider:
      - Emergency or safety keywords
      - Legal or compliance deadlines
      - Financial urgency
      - Tenant satisfaction impact
      - Time-sensitive nature
    PROMPT
  end

  def parse_categorization_response(response)
    {
      category: response['category'] || 'other',
      confidence: response['confidence'] || 0.0,
      reasoning: response['reasoning'] || 'No reasoning provided'
    }
  end

  def parse_task_extraction_response(response)
    tasks = response['tasks'] || []
    {
      tasks: tasks.map do |task|
        {
          title: task['title'],
          description: task['description'],
          task_type: task['task_type'] || 'other',
          priority: task['priority'] || 'normal',
          suggested_due_date: parse_date(task['suggested_due_date']),
          confidence: task['confidence'] || 0.0,
          reasoning: task['reasoning']
        }
      end,
      confidence: response['confidence'] || 0.0,
      reasoning: response['reasoning'] || 'No reasoning provided'
    }
  end

  def parse_property_matching_response(response, properties)
    property_id = response['property_id']
    property = properties.find { |p| p.id == property_id } if property_id
    
    {
      property: property,
      confidence: response['confidence'] || 0.0,
      reasoning: response['reasoning'] || 'No reasoning provided',
      matched_text: response['matched_text']
    }
  end

  def parse_priority_response(response)
    {
      priority: response['priority'] || 'normal',
      confidence: response['confidence'] || 0.0,
      reasoning: response['reasoning'] || 'No reasoning provided',
      urgency_indicators: response['urgency_indicators'] || []
    }
  end

  def calculate_overall_confidence(confidences)
    valid_confidences = confidences.compact.select { |c| c > 0 }
    return 0.0 if valid_confidences.empty?
    
    valid_confidences.sum.to_f / valid_confidences.length
  end

  def calculate_processing_cost(email)
    # Estimate cost based on tokens used and model pricing
    # GPT-4o-mini pricing: ~$0.15 per 1M input tokens, ~$0.60 per 1M output tokens
    estimated_input_tokens = estimate_tokens(email.body_preview || email.subject)
    estimated_output_tokens = 300 # Average output
    
    input_cost = (estimated_input_tokens / 1_000_000.0) * 0.15
    output_cost = (estimated_output_tokens / 1_000_000.0) * 0.60
    
    input_cost + output_cost
  end

  def estimate_tokens(text)
    # Rough estimation: 1 token ≈ 4 characters
    (text&.length || 0) / 4
  end

  def parse_date(date_string)
    return nil unless date_string
    Date.parse(date_string)
  rescue Date::Error
    nil
  end

  def create_analysis_log(email, analysis_type)
    @organization.ai_analysis_logs.create!(
      email: email,
      analysis_type: analysis_type,
      status: 'pending',
      input_data: {
        subject: email.subject,
        sender: email.sender_display_name,
        preview: email.body_preview
      }.to_json
    )
  end

  def update_email_with_results(email, results)
    email.update!(
      category: results[:category],
      priority_level: results[:priority_level],
      confidence_score: results[:confidence_score],
      ai_analysis_summary: results[:extracted_data].to_json
    )
  end

  def should_auto_create_tasks?(results)
    # Only auto-create tasks if confidence is high and tasks are suggested
    results[:confidence_score] >= 0.8 && 
    results[:suggested_tasks].present? &&
    results[:suggested_tasks].any? { |task| task[:confidence] >= 0.8 }
  end

  def auto_create_tasks(email, results)
    high_confidence_tasks = results[:suggested_tasks].select { |task| task[:confidence] >= 0.8 }
    
    high_confidence_tasks.each do |task_data|
      create_task_from_ai_analysis(email, task_data, results[:matched_property])
    end
  end

  def create_task_from_ai_analysis(email, task_data, matched_property)
    # Handle Section 8 specific task creation
    task_params = {
      title: task_data[:title],
      description: task_data[:description],
      task_type: task_data[:task_type],
      priority: task_data[:priority],
      due_date: task_data[:suggested_due_date],
      property: matched_property,
      email: email,
      is_auto_generated: true,
      ai_confidence: task_data[:confidence],
      status: 'pending'
    }

    # Add Section 8 specific fields
    if email.inspection_email?
      housing_authority = email.detect_housing_authority
      task_params[:housing_authority] = housing_authority if housing_authority
      task_params[:inspection_type] = detect_inspection_type(email)
      task_params[:property_address] = email.extract_property_address
    elsif email.utility_bill_email?
      utility_info = email.detect_utility_company
      task_params[:utility_company] = utility_info[:company_key] if utility_info
      task_params[:property_address] = email.extract_property_address
    end

    @organization.tasks.create!(task_params)
  rescue => e
    Rails.logger.error "Failed to create auto-generated task: #{e.message}"
  end

  # Section 8 specific task extraction
  def extract_section8_tasks(email)
    if email.inspection_email?
      extract_inspection_tasks(email)
    elsif email.utility_bill_email?
      extract_utility_tasks(email)
    elsif email.work_order_email?
      extract_work_order_tasks(email)
    elsif email.rfta_email?
      extract_rfta_tasks(email)
    else
      extract_tasks(email)
    end
  end

  def extract_inspection_tasks(email)
    inspection_date = email.extract_inspection_date
    property_address = email.extract_property_address
    housing_authority = email.detect_housing_authority

    {
      tasks: [{
        title: "Prepare for #{housing_authority&.display_name || 'Housing Authority'} Inspection",
        description: "Property inspection scheduled at #{property_address}. Ensure property is ready and accessible.",
        task_type: detect_inspection_task_type(email),
        priority: housing_authority&.priority_level || 'high',
        suggested_due_date: inspection_date&.prev_day, # Day before inspection
        confidence: 0.9,
        reasoning: "Inspection email detected with clear date and address"
      }],
      confidence: 0.9,
      reasoning: "High confidence inspection email"
    }
  end

  def extract_utility_tasks(email)
    utility_info = email.detect_utility_company
    bill_info = Utility.extract_bill_info(email.body_preview, email.subject)
    
    return { tasks: [], confidence: 0.0, reasoning: "No utility info found" } unless utility_info

    {
      tasks: [{
        title: "Pay #{utility_info[:company_name]} Bill",
        description: "Utility bill due#{bill_info[:due_date] ? " on #{bill_info[:due_date].strftime('%m/%d/%Y')}" : ''}#{bill_info[:amount] ? " - Amount: $#{bill_info[:amount]}" : ''}",
        task_type: 'utility_payment',
        priority: determine_utility_priority(bill_info[:due_date]),
        suggested_due_date: bill_info[:due_date]&.prev_day,
        confidence: 0.85,
        reasoning: "Utility bill detected with company and amount information"
      }],
      confidence: 0.85,
      reasoning: "Utility bill successfully parsed"
    }
  end

  def extract_work_order_tasks(email)
    {
      tasks: [{
        title: "Review Work Order Update",
        description: "Work order status update received. Review completion and any follow-up actions needed.",
        task_type: 'work_order',
        priority: 'normal',
        suggested_due_date: Date.current + 1.day,
        confidence: 0.7,
        reasoning: "Work order update email detected"
      }],
      confidence: 0.7,
      reasoning: "Work order email detected"
    }
  end

  def extract_rfta_tasks(email)
    {
      tasks: [{
        title: "Review RFTA Completion",
        description: "Request for Tenant Action (RFTA) completion notice received. Verify work completed and update records.",
        task_type: 'inspection_reinspection',
        priority: 'high',
        suggested_due_date: Date.current + 2.days,
        confidence: 0.8,
        reasoning: "RFTA completion email detected"
      }],
      confidence: 0.8,
      reasoning: "RFTA email successfully identified"
    }
  end

  # Enhanced property matching with Section 8 context
  def match_property_enhanced(email)
    # First try the basic AI matching
    ai_result = match_property(email)
    
    # If AI found a match, use it
    return ai_result if ai_result[:property]

    # Try rule-based matching for Section 8 emails
    extracted_address = email.extract_property_address
    if extracted_address
      # Try to find property by address matching
      properties = @organization.properties
      matched_property = find_property_by_address(properties, extracted_address)
      
      if matched_property
        return {
          property: matched_property,
          confidence: 0.8,
          reasoning: "Address extracted from email matches property: #{extracted_address}",
          matched_text: extracted_address
        }
      end
    end

    # Return no match
    { property: nil, confidence: 0.0, reasoning: 'No property match found' }
  end

  def analyze_section8_specifics(email)
    section8_data = {}

    # Detect housing authority
    housing_authority = email.detect_housing_authority
    section8_data[:housing_authority] = housing_authority.attributes if housing_authority

    # Detect utility company  
    utility_info = email.detect_utility_company
    section8_data[:utility_company] = utility_info if utility_info

    # Extract inspection details
    if email.inspection_email?
      section8_data[:inspection_date] = email.extract_inspection_date
      section8_data[:inspection_type] = detect_inspection_type(email)
    end

    # Extract utility bill details
    if email.utility_bill_email?
      section8_data[:bill_info] = Utility.extract_bill_info(email.body_preview, email.subject)
    end

    section8_data
  end

  def detect_inspection_type(email)
    subject = email.subject.downcase
    
    return 'annual' if subject.include?('annual')
    return 'initial' if subject.include?('initial') && !subject.include?('reinspection')
    return 're_inspection' if subject.include?('reinspection')
    return 'hqs' if subject.include?('hqs')
    return 'work_order' if subject.include?('work order')
    
    'other'
  end

  def detect_inspection_task_type(email)
    inspection_type = detect_inspection_type(email)
    
    case inspection_type
    when 'annual'
      'inspection_annual'
    when 'initial'
      'inspection_initial'
    when 're_inspection'
      'inspection_reinspection'
    when 'hqs'
      'inspection_hqs'
    else
      'inspection_annual'
    end
  end

  def determine_utility_priority(due_date)
    return 'normal' unless due_date
    
    days_until_due = (due_date - Date.current).to_i
    
    case days_until_due
    when ...0
      'urgent'  # Overdue
    when 0..2
      'urgent'  # Due in 2 days or less
    when 3..7
      'high'    # Due within a week
    else
      'normal'  # More than a week
    end
  end

  def find_property_by_address(properties, extracted_address)
    # Clean and normalize the address for matching
    normalized_extracted = normalize_address(extracted_address)
    
    properties.find do |property|
      normalized_property = normalize_address(property.full_address)
      
      # Check for exact match or partial match
      normalized_extracted.include?(normalized_property) ||
      normalized_property.include?(normalized_extracted) ||
      address_similarity_match?(normalized_extracted, normalized_property)
    end
  end

  def normalize_address(address)
    return '' unless address
    
    # Convert to lowercase and remove extra spaces
    normalized = address.downcase.strip.gsub(/\s+/, ' ')
    
    # Replace common address abbreviations
    replacements = {
      'street' => 'st',
      'avenue' => 'ave',
      'road' => 'rd',
      'drive' => 'dr',
      'lane' => 'ln',
      'way' => 'way',
      'circle' => 'cir',
      'court' => 'ct',
      'boulevard' => 'blvd',
      'place' => 'pl'
    }
    
    replacements.each { |long, short| normalized.gsub!(long, short) }
    
    # Remove common punctuation
    normalized.gsub(/[.,#]/, '').strip
  end

  def address_similarity_match?(addr1, addr2)
    # Extract street numbers and compare
    number1 = addr1.match(/\d+/)&.[](0)
    number2 = addr2.match(/\d+/)&.[](0)
    
    # If street numbers don't match, it's not the same property
    return false unless number1 && number2 && number1 == number2
    
    # Check if the street names have significant overlap
    words1 = addr1.split.reject { |w| w.match(/^\d+$/) }
    words2 = addr2.split.reject { |w| w.match(/^\d+$/) }
    
    common_words = words1 & words2
    common_words.length >= [words1.length, words2.length].min * 0.6
  end
end
