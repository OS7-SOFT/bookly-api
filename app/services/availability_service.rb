class AvailabilityService
  Result = Struct.new(:success?, :data, :errors, keyword_init: true)

  SLOT_INTERVAL_MINUTES = 30

  def self.call(business_id:, bookable_service_id:, date:)
    new(
      business_id: business_id,
      bookable_service_id: bookable_service_id,
      date: date
    ).call
  end

  def initialize(business_id:, bookable_service_id:, date:)
    @business_id = business_id
    @bookable_service_id = bookable_service_id
    @date = date
    @errors = []
  end

  def call
    load_records
    return failure if errors.any?

    normalize_date
    return failure if errors.any?

    validate_business
    validate_bookable_service
    return failure if errors.any?

    load_working_hour
    return success(empty_response) if closed_or_not_configured?

    available_slots = build_available_slots

    success(
      {
        date: date.to_s,
        business_id: business.id,
        bookable_service_id: bookable_service.id,
        duration_minutes: bookable_service.duration_minutes,
        slot_interval_minutes: SLOT_INTERVAL_MINUTES,
        available_slots: available_slots
      }
    )
  end

  private

  attr_reader :business,
              :bookable_service,
              :date,
              :working_hour,
              :errors

  def load_records
    @business = Business.find_by(id: @business_id)
    errors << "Business not found" if business.blank?

    @bookable_service = BookableService.find_by(id: @bookable_service_id)
    errors << "Bookable service not found" if bookable_service.blank?
  end

  def normalize_date
    @date = Date.parse(@date.to_s)
  rescue ArgumentError, TypeError
    errors << "Date is invalid"
  end

  def validate_business
    return if business.blank?

    errors << "Business is not active" unless business.is_active?
  end

  def validate_bookable_service
    return if business.blank? || bookable_service.blank?

    unless bookable_service.business_id == business.id
      errors << "Bookable service does not belong to this business"
    end

    errors << "Bookable service is not active" unless bookable_service.is_active?
  end

  def load_working_hour
    @working_hour = business.working_hours.find_by(
      day_of_week: day_of_week_for(date)
    )
  end

  def closed_or_not_configured?
    working_hour.blank? || working_hour.is_closed?
  end

  def empty_response
    {
      date: date.to_s,
      business_id: business.id,
      bookable_service_id: bookable_service.id,
      duration_minutes: bookable_service.duration_minutes,
      slot_interval_minutes: SLOT_INTERVAL_MINUTES,
      available_slots: []
    }
  end

  def build_available_slots
    slots = []

    current_slot_start = datetime_for(date, working_hour.start_time)
    working_end_at = datetime_for(date, working_hour.end_time)

    while current_slot_start + bookable_service.duration_minutes.minutes <= working_end_at
      slot_end = current_slot_start + bookable_service.duration_minutes.minutes

      if future_slot?(current_slot_start) && !conflicting_slot?(current_slot_start, slot_end)
        slots << current_slot_start.strftime("%H:%M")
      end

      current_slot_start += SLOT_INTERVAL_MINUTES.minutes
    end

    slots
  end

  def future_slot?(slot_start)
    slot_start > Time.current
  end

  def conflicting_slot?(slot_start, slot_end)
    business
      .bookings
      .active_for_conflict
      .where("start_at < ? AND ? < end_at", slot_end, slot_start)
      .exists?
  end

  def datetime_for(date, time)
    Time.zone.local(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.min,
      time.sec
    )
  end

  def day_of_week_for(date)
    date.strftime("%A").downcase
  end

  def success(data)
    Result.new(
      success?: true,
      data: data,
      errors: []
    )
  end

  def failure(extra_errors = nil)
    Result.new(
      success?: false,
      data: nil,
      errors: Array(extra_errors || errors)
    )
  end
end
