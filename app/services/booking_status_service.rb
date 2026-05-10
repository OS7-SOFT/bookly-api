class BookingStatusService
  Result = Struct.new(:success?, :booking, :errors, keyword_init: true)

  ACTIONS = {
    confirm: :confirmed,
    cancel: :cancelled,
    complete: :completed,
    mark_as_no_show: :no_show
  }.freeze

  def self.call(booking:, action:)
    new(booking: booking, action: action).call
  end

  def initialize(booking:, action:)
    @booking = booking
    @action = action.to_sym
    @errors = []
  end

  def call
    validate_action
    return failure if errors.any?

    validate_transition
    return failure if errors.any?

    update_status
  end

  private

  attr_reader :booking, :action, :errors

  def validate_action
    errors << "Invalid booking status action" unless ACTIONS.key?(action)
  end

  def validate_transition
    case action
    when :confirm
      validate_confirm
    when :cancel
      validate_cancel
    when :complete
      validate_complete
    when :mark_as_no_show
      validate_no_show
    end
  end

  def validate_confirm
    return if booking.pending?

    errors << "Only pending bookings can be confirmed"
  end

  def validate_cancel
    return if booking.pending? || booking.confirmed?

    errors << "Only pending or confirmed bookings can be cancelled"
  end

  def validate_complete
    unless booking.confirmed?
      errors << "Only confirmed bookings can be completed"
      return
    end

    if booking.end_at > Time.current
      errors << "Booking cannot be completed before it ends"
    end
  end

  def validate_no_show
    unless booking.pending? || booking.confirmed?
      errors << "Only pending or confirmed bookings can be marked as no-show"
      return
    end

    if booking.start_at > Time.current
      errors << "Booking cannot be marked as no-show before it starts"
    end
  end

  def update_status
    new_status = ACTIONS.fetch(action)

    if booking.update(status: new_status)
      success(booking)
    else
      failure(booking.errors.full_messages)
    end
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
      booking: booking,
      errors: Array(extra_errors || errors)
    )
  end
end
