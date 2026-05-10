class OwnerMailer < ApplicationMailer
  def new_booking_notification(booking)
    @booking = booking
    @business = booking.business
    @bookable_service = booking.bookable_service
    @owner = @business.user

    mail(
      to: @owner.email,
      subject: "New booking received"
    )
  end
end
