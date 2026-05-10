class CreateBookingService
  Result = Struct.new(:success?, :booking, :errors, keyword_init: true)

  def self.call(**args)
    new(**args).call
  end

  def initialize(
    business_id:,
    bookable_service_id:,
    customer_name:,
    customer_phone:,
    start_at:,
    customer_email: nil,
    notes: nil
  )
    @business_id = business_id
    @bookable_service_id = bookable_service_id
    @customer_name = customer_name
    @customer_phone = customer_phone
    @customer_email = customer_email
    @start_at = start_at
    @notes = notes
    @errors = []
  end

  def call
    load_records
    return failure if errors.any?

    normalize_start_at
    return failure if errors.any?

    calculate_end_at

    validate_business
    validate_bookable_service
    validate_booking_time
    validate_working_hours
    validate_no_conflict

    return failure if errors.any?

    create_booking
  end

  private

  attr_reader :business,
              :bookable_service,
              :start_at,
              :end_at,
              :errors

  def load_records
    @business = Business.find_by(id: @business_id)
    errors << "Business not found" if business.blank?

    @bookable_service = BookableService.find_by(id: @bookable_service_id)
    errors << "Bookable service not found" if bookable_service.blank?
  end

  def normalize_start_at
    @start_at = Time.zone.parse(@start_at.to_s)

    errors << "Start at is invalid" if @start_at.blank?
  rescue ArgumentError, TypeError
    errors << "Start at is invalid"
  end

  def calculate_end_at
    return if bookable_service.blank? || start_at.blank?

    @end_at = start_at + bookable_service.duration_minutes.minutes
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

  def validate_booking_time
    return if start_at.blank? || end_at.blank?

    errors << "Booking time must be in the future" if start_at <= Time.current
  end

  def validate_working_hours
    return if business.blank? || start_at.blank? || end_at.blank?

    working_hour = business.working_hours.find_by(
      day_of_week: day_of_week_for(start_at)
    )

    if working_hour.blank?
      errors << "Working hours are not configured for this day"
      return
    end

    if working_hour.is_closed?
      errors << "Business is closed on this day"
      return
    end

    unless inside_working_hours?(working_hour)
      errors << "Booking time is outside working hours"
    end
  end

  def validate_no_conflict
    return if business.blank? || start_at.blank? || end_at.blank?

    conflict_exists = business
      .bookings
      .active_for_conflict
      .where("start_at < ? AND ? < end_at", end_at, start_at)
      .exists?

    errors << "Selected time is already booked" if conflict_exists
  end

  def create_booking
    booking = Booking.new(
      business: business,
      bookable_service: bookable_service,
      customer_name: @customer_name,
      customer_phone: @customer_phone,
      customer_email: @customer_email,
      start_at: start_at,
      end_at: end_at,
      status: :pending,
      notes: @notes
    )

    if booking.save
      success(booking)
    else
      failure(booking.errors.full_messages)
    end
  end

  def inside_working_hours?(working_hour)
    booking_start_seconds = seconds_since_midnight(start_at)
    booking_end_seconds = seconds_since_midnight(end_at)

    working_start_seconds = seconds_since_midnight(working_hour.start_time)
    working_end_seconds = seconds_since_midnight(working_hour.end_time)

    booking_start_seconds >= working_start_seconds &&
      booking_end_seconds <= working_end_seconds
  end

  def seconds_since_midnight(value)
    value.hour.hours + value.min.minutes + value.sec.seconds
  end

  def day_of_week_for(datetime)
    datetime.strftime("%A").downcase
  end

  def success(booking)
    Result.new(
      success?: true,
      booking: booking,
      errors: []
    )
  end

  def failure(extra_errors = nil)
    Result.new(
      success?: false,
      booking: nil,
      errors: Array(extra_errors || errors)
    )
  end
end
