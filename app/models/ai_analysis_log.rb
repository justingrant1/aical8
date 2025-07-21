class AiAnalysisLog < ApplicationRecord
  belongs_to :organization
  belongs_to :email, optional: true

  validates :analysis_type, inclusion: { 
    in: %w[email_categorization task_extraction property_matching sentiment_analysis] 
  }
  validates :status, inclusion: { in: %w[pending processing completed failed] }

  scope :recent, -> { order(created_at: :desc) }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :by_type, ->(type) { where(analysis_type: type) }
  scope :high_confidence, -> { where('confidence_score >= 0.8') }
  scope :low_confidence, -> { where('confidence_score < 0.7') }

  def completed?
    status == 'completed'
  end

  def failed?
    status == 'failed'
  end

  def processing?
    status == 'processing'
  end

  def pending?
    status == 'pending'
  end

  def high_confidence?
    confidence_score.present? && confidence_score >= 0.8
  end

  def low_confidence?
    confidence_score.present? && confidence_score < 0.7
  end

  def has_feedback?
    user_feedback.present?
  end

  def positive_feedback?
    user_feedback == 'correct'
  end

  def negative_feedback?
    user_feedback == 'incorrect'
  end

  # Cost tracking
  def self.total_cost_today
    where(created_at: Date.current.beginning_of_day..Date.current.end_of_day)
      .sum(:processing_cost) || 0.0
  end

  def self.total_cost_this_month
    where(created_at: Date.current.beginning_of_month..Date.current.end_of_month)
      .sum(:processing_cost) || 0.0
  end

  # Analysis results
  def output_data_parsed
    return {} unless output_data.present?
    
    begin
      JSON.parse(output_data)
    rescue JSON::ParserError
      {}
    end
  end

  def input_data_parsed
    return {} unless input_data.present?
    
    begin
      JSON.parse(input_data)
    rescue JSON::ParserError
      {}
    end
  end

  # Performance tracking
  def self.average_confidence_score
    where.not(confidence_score: nil).average(:confidence_score) || 0.0
  end

  def self.success_rate
    total = count
    return 0.0 if total.zero?
    
    successful = completed.count
    (successful.to_f / total * 100).round(2)
  end

  def processing_time_seconds
    return nil unless started_at && completed_at
    (completed_at - started_at).to_f
  end
end
