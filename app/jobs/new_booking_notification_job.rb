class NewBookingNotificationJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 10.seconds, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(booking_id)
    booking = Booking.includes(:business, :bookable_service).find(booking_id)

    Notifications::NewBookingNotifier.call(booking: booking)
  end
end
