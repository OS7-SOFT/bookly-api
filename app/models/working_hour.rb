class WorkingHour < ApplicationRecord
  belongs_to :business

  enum :day_of_week, {
    sunday: 0,
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6
  }

  validates :day_of_week, presence: true
  validates :day_of_week, uniqueness: { scope: :business_id }

  validates :start_time, presence: true, unless: :is_closed?
  validates :end_time, presence: true, unless: :is_closed?

  validate :start_time_must_be_before_end_time, unless: :is_closed?

  private

  def start_time_must_be_before_end_time
    return if start_time.blank? || end_time.blank?

    errors.add(:start_time, "must be before end time") if start_time >= end_time
  end
end
