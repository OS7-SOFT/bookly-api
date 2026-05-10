class BookingPresenter
  def initialize(booking)
    @booking = booking
  end

  def as_json(*)
    {
      id: @booking.id,
      business_id: @booking.business_id,
      bookable_service_id: @booking.bookable_service_id,
      customer_name: @booking.customer_name,
      customer_phone: @booking.customer_phone,
      customer_email: @booking.customer_email,
      start_at: @booking.start_at,
      end_at: @booking.end_at,
      status: @booking.status,
      notes: @booking.notes,
      created_at: @booking.created_at,
      updated_at: @booking.updated_at
    }
  end
end
