# db/seeds.rb - Initial data for development and demo

puts "🌱 Seeding database..."

# Create sample housing authorities for testing
housing_authorities = [
  {
    key: 'sf_housing_authority',
    display_name: 'San Francisco Housing Authority',
    email_domains: ['sfha.org', 'sf.gov'].to_json,
    detection_keywords: ['San Francisco Housing Authority', 'SFHA', 'HQS inspection', 'Housing Quality Standards'].to_json,
    priority_level: 'high',
    contact_email: 'info@sfha.org',
    contact_phone: '(415) 345-4300',
    city: 'San Francisco',
    state: 'CA',
    website_url: 'https://sfha.org',
    notes: 'Primary housing authority for San Francisco area'
  },
  {
    key: 'nycha',
    display_name: 'New York City Housing Authority',
    email_domains: ['nycha.nyc.gov', 'nyc.gov'].to_json,
    detection_keywords: ['NYCHA', 'New York City Housing Authority', 'annual inspection', 'HQS'].to_json,
    priority_level: 'high',
    contact_email: 'customer.service@nycha.nyc.gov',
    contact_phone: '(718) 707-7771',
    city: 'New York',
    state: 'NY',
    website_url: 'https://www1.nyc.gov/site/nycha',
    notes: 'Largest public housing authority in North America'
  },
  {
    key: 'la_housing_authority',
    display_name: 'Housing Authority of City of Los Angeles',
    email_domains: ['hacla.org', 'lacity.org'].to_json,
    detection_keywords: ['HACLA', 'Housing Authority of Los Angeles', 'Section 8 inspection'].to_json,
    priority_level: 'high',
    contact_email: 'info@hacla.org',
    contact_phone: '(213) 252-2500',
    city: 'Los Angeles',
    state: 'CA',
    website_url: 'https://hacla.org',
    notes: 'Serves Los Angeles area Section 8 properties'
  }
]

housing_authorities.each do |ha_data|
  HousingAuthority.find_or_create_by(key: ha_data[:key]) do |ha|
    ha.assign_attributes(ha_data)
  end
end
puts "✅ Created #{HousingAuthority.count} housing authorities"

# Create sample utility companies for testing
utilities = [
  {
    company_key: 'pge',
    company_name: 'Pacific Gas & Electric',
    email_domains: ['pge.com', 'pacificgaselectric.com'].to_json,
    detection_keywords: ['PG&E', 'Pacific Gas', 'electric bill', 'gas bill', 'utility bill'].to_json,
    utility_type: 'electric_gas',
    service_area: 'Northern California',
    customer_service_phone: '1-800-743-5000',
    website_url: 'https://pge.com',
    bill_format_notes: 'PDF format with account number in subject line'
  },
  {
    company_key: 'con_edison',
    company_name: 'Consolidated Edison',
    email_domains: ['coned.com', 'conedison.com'].to_json,
    detection_keywords: ['Con Ed', 'ConEd', 'Consolidated Edison', 'electric bill'].to_json,
    utility_type: 'electric',
    service_area: 'New York City',
    customer_service_phone: '1-800-752-6633',
    website_url: 'https://coned.com',
    bill_format_notes: 'HTML and PDF formats available'
  },
  {
    company_key: 'ladwp',
    company_name: 'Los Angeles Department of Water and Power',
    email_domains: ['ladwp.com', 'lacity.org'].to_json,
    detection_keywords: ['LADWP', 'Los Angeles Water and Power', 'DWP bill'].to_json,
    utility_type: 'electric_water',
    service_area: 'Los Angeles',
    customer_service_phone: '1-800-342-5397',
    website_url: 'https://ladwp.com',
    bill_format_notes: 'PDF bills with property address in filename'
  },
  {
    company_key: 'southern_california_gas',
    company_name: 'Southern California Gas Company',
    email_domains: ['socalgas.com', 'sempra.com'].to_json,
    detection_keywords: ['SoCalGas', 'Southern California Gas', 'natural gas bill'].to_json,
    utility_type: 'gas',
    service_area: 'Southern California',
    customer_service_phone: '1-800-427-2200',
    website_url: 'https://socalgas.com',
    bill_format_notes: 'Monthly PDF statements'
  }
]

utilities.each do |utility_data|
  Utility.find_or_create_by(company_key: utility_data[:company_key]) do |utility|
    utility.assign_attributes(utility_data)
  end
end
puts "✅ Created #{Utility.count} utility companies"

# Create demo organization for development
demo_org = Organization.find_or_create_by(slug: 'demo-properties') do |org|
  org.name = 'Demo Property Management'
  org.contact_email = 'admin@demoproperties.com'
  org.phone_number = '(555) 123-4567'
  org.address = '123 Main Street'
  org.city = 'San Francisco'
  org.state = 'CA'
  org.zip_code = '94102'
  org.subscription_status = 'active'
  org.subscription_tier = 'professional'
  org.subscription_expires_at = 1.year.from_now
  org.settings = {
    'ai_analysis_enabled' => true,
    'auto_task_creation' => true,
    'email_notifications' => true,
    'max_properties' => 100
  }
end

puts "✅ Created demo organization: #{demo_org.name}"

# Create demo user profile
demo_user = UserProfile.find_or_create_by(
  organization: demo_org,
  email: 'demo@demoproperties.com'
) do |user|
  user.supabase_user_id = 'demo-user-' + SecureRandom.uuid
  user.first_name = 'Demo'
  user.last_name = 'Admin'
  user.role = 'admin'
  user.phone_number = '(555) 123-4567'
  user.preferences = {
    'dashboard_layout' => 'standard',
    'email_frequency' => 'daily',
    'time_zone' => 'America/Los_Angeles'
  }
end

puts "✅ Created demo user: #{demo_user.email}"

# Create sample properties for demonstration
sample_properties = [
  {
    address_line_1: '123 Oak Street',
    city: 'San Francisco',
    state: 'CA',
    zip_code: '94102',
    unit_number: 'Apt 2A',
    property_type: 'apartment',
    occupancy_status: 'occupied',
    monthly_rent: 2800.00,
    tenant_name: 'John Smith',
    tenant_email: 'john.smith@email.com',
    housing_authority_key: 'sf_housing_authority',
    subsidy_type: 'section8',
    tenant_portion: 800.00,
    subsidy_portion: 2000.00,
    next_inspection_date: 3.months.from_now,
    inspection_status: 'scheduled'
  },
  {
    address_line_1: '456 Pine Avenue',
    city: 'San Francisco',
    state: 'CA',
    zip_code: '94110',
    property_type: 'single_family',
    occupancy_status: 'vacant',
    monthly_rent: 3200.00,
    last_inspection_date: 2.months.ago,
    next_inspection_date: 10.months.from_now,
    inspection_status: 'passed'
  },
  {
    address_line_1: '789 Market Street',
    unit_number: 'Unit 5B',
    city: 'San Francisco',
    state: 'CA',
    zip_code: '94103',
    property_type: 'apartment',
    occupancy_status: 'occupied',
    monthly_rent: 2400.00,
    tenant_name: 'Maria Garcia',
    tenant_email: 'maria.garcia@email.com',
    housing_authority_key: 'sf_housing_authority',
    subsidy_type: 'section8',
    tenant_portion: 600.00,
    subsidy_portion: 1800.00,
    next_inspection_date: 1.month.from_now,
    inspection_status: 'scheduled'
  }
]

sample_properties.each do |property_data|
  Property.find_or_create_by(
    organization: demo_org,
    address_line_1: property_data[:address_line_1],
    unit_number: property_data[:unit_number]
  ) do |property|
    property.assign_attributes(property_data)
  end
end

puts "✅ Created #{Property.count} sample properties"

puts "🎉 Database seeding completed!"
puts "---"
puts "Demo Organization: #{demo_org.name} (#{demo_org.slug})"
puts "Demo User: #{demo_user.email} (#{demo_user.role})"
puts "Properties: #{Property.count}"
puts "Housing Authorities: #{HousingAuthority.count}"
puts "Utility Companies: #{Utility.count}"
puts "---"
puts "You can now test the API with the demo organization data."
