class Booking < ApplicationRecord
  belongs_to :business
  belongs_to :bookable_service

  enum :status, {
    pending: 0,
    confirmed: 1,
    cancelled: 2,
    completed: 3,
    no_show: 4
  }

  normalizes :customer_email, with: ->(email) { email&.strip&.downcase }
  normalizes :customer_phone, with: ->(phone) { phone&.strip }

  validates :customer_name, presence: true, length: { maximum: 100 }
  validates :customer_phone, presence: true, length: { maximum: 30 }

  validates :customer_email,
            format: { with: URI::MailTo::EMAIL_REGEXP },
            allow_blank: true

  validates :start_at, presence: true
  validates :end_at, presence: true
  validates :status, presence: true
  validates :notes, length: { maximum: 1_000 }, allow_blank: true

  validate :end_at_must_be_after_start_at
  validate :bookable_service_must_belong_to_business

  scope :active_for_conflict, -> { where.not(status: :cancelled) }
  scope :upcoming, -> { where("start_at >= ?", Time.current) }
  scope :past, -> { where("end_at < ?", Time.current) }
  scope :for_date, ->(date) {
    where(start_at: date.beginning_of_day..date.end_of_day)
  }

  private

  def end_at_must_be_after_start_at
    return if start_at.blank? || end_at.blank?

    errors.add(:end_at, "must be after start at") if end_at <= start_at
  end

  def bookable_service_must_belong_to_business
    return if business_id.blank? || bookable_service.blank?

    if bookable_service.business_id != business_id
      errors.add(:bookable_service, "must belong to the same business")
    end
  end
end
