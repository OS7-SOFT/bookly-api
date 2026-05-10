module Notifications
  class NewBookingNotifier
    Result = Struct.new(:success?, :errors, keyword_init: true)

    def self.call(booking:)
      new(booking: booking).call
    end

    def initialize(booking:)
      @booking = booking
      @errors = []
    end

    def call
      validate_booking
      return failure if errors.any?

      notify_owner

      success
    rescue StandardError => e
      failure([ e.message ])
    end

    private

    attr_reader :booking, :errors

    def validate_booking
      errors << "Booking is required" if booking.blank?
      errors << "Booking must be persisted" if booking.present? && !booking.persisted?
      errors << "Booking business is required" if booking.present? && booking.business.blank?
      errors << "Booking owner is required" if booking.present? && booking.business&.user.blank?
      errors << "Owner email is required" if booking.present? && booking.business&.user&.email.blank?
    end

    def notify_owner
      OwnerMailer
        .new_booking_notification(booking)
        .deliver_now
    end

    def success
      Result.new(success?: true, errors: [])
    end

    def failure(extra_errors = nil)
      Result.new(success?: false, errors: Array(extra_errors || errors))
    end
  end
end
