class Api::V1::DashboardController < ApplicationController
  
  def index
    render json: {
      critical_items: critical_items_data,
      properties_overview: properties_overview_data,
      upcoming_deadlines: upcoming_deadlines_data,
      recent_emails: recent_emails_data,
      financial_summary: financial_summary_data,
      compliance_status: compliance_status_data
    }
  end

  private

  def critical_items_data
    urgent_tasks = current_organization.tasks.urgent.active.limit(5)
    
    {
      count: urgent_tasks.count,
      items: urgent_tasks.map do |task|
        {
          id: task.id,
          title: task.title,
          property: task.property&.short_address,
          due_date: task.due_date,
          days_until_due: task.days_until_due,
          priority: task.priority,
          task_type: task.task_type
        }
      end
    }
  end

  def properties_overview_data
    properties = current_organization.properties
    
    {
      total: properties.count,
      occupied: properties.occupied.count,
      vacant: properties.vacant.count,
      maintenance: properties.needs_maintenance.count,
      occupancy_rate: calculate_occupancy_rate(properties)
    }
  end

  def upcoming_deadlines_data
    upcoming_tasks = current_organization.tasks
      .active
      .where('due_date BETWEEN ? AND ?', Date.current, Date.current + 30.days)
      .order(:due_date)
      .limit(10)

    {
      count: upcoming_tasks.count,
      tasks: upcoming_tasks.map do |task|
        {
          id: task.id,
          title: task.title,
          property: task.property&.short_address,
          due_date: task.due_date,
          days_until_due: task.days_until_due,
          priority: task.priority,
          task_type: task.task_type,
          overdue: task.overdue?
        }
      end
    }
  end

  def recent_emails_data
    recent_emails = current_organization.emails
      .high_priority
      .recent
      .limit(5)

    {
      count: recent_emails.count,
      emails: recent_emails.map do |email|
        {
          id: email.id,
          subject: email.subject,
          sender: email.sender_display_name,
          received_at: email.received_at,
          category: email.category,
          priority_level: email.priority_level,
          confidence_score: email.confidence_score,
          has_tasks: email.tasks.exists?
        }
      end
    }
  end

  def financial_summary_data
    properties = current_organization.properties.occupied
    
    {
      total_monthly_rent: properties.sum(:rent_amount) || 0,
      properties_count: properties.count,
      # These would be calculated based on actual financial data
      # For now, using estimated values
      pending_payments: calculate_pending_payments,
      upcoming_expenses: calculate_upcoming_expenses
    }
  end

  def compliance_status_data
    total_properties = current_organization.properties.count
    return { total: 0, compliant: 0, pending: 0, overdue: 0, rate: 100 } if total_properties.zero?

    # This would be calculated based on compliance tasks and inspections
    # For now, using sample calculations
    compliance_tasks = current_organization.tasks.where(task_type: ['inspection', 'compliance'])
    overdue_compliance = compliance_tasks.overdue.count
    pending_compliance = compliance_tasks.pending.count
    compliant_count = [total_properties - overdue_compliance - pending_compliance, 0].max

    {
      total: total_properties,
      compliant: compliant_count,
      pending: pending_compliance,
      overdue: overdue_compliance,
      rate: ((compliant_count.to_f / total_properties) * 100).round
    }
  end

  def calculate_occupancy_rate(properties)
    return 100 if properties.count.zero?
    occupied = properties.occupied.count
    ((occupied.to_f / properties.count) * 100).round
  end

  def calculate_pending_payments
    # This would integrate with actual payment/accounting system
    # For now, return estimated based on rent amounts and due dates
    current_organization.properties.occupied.sum(:rent_amount) * 0.1 # 10% estimated pending
  end

  def calculate_upcoming_expenses
    # This would be calculated from maintenance tasks and scheduled expenses
    # For now, return estimated value
    current_organization.tasks
      .where(task_type: ['maintenance', 'financial'])
      .where('due_date BETWEEN ? AND ?', Date.current, Date.current + 30.days)
      .count * 500 # Estimated $500 per task
  end
end
