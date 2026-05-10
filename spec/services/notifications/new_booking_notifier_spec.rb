require "rails_helper"

RSpec.describe Notifications::NewBookingNotifier do
  describe ".call" do
    let!(:user) do
      User.create!(
        full_name: "Owner User",
        email: "owner@example.com",
        password: "password123"
      )
    end

    let!(:business) do
      Business.create!(
        user: user,
        name: "Bookly Center",
        is_active: true
      )
    end

    let!(:bookable_service) do
      BookableService.create!(
        business: business,
        name: "Consultation",
        duration_minutes: 30,
        price: 20,
        is_active: true
      )
    end

    let!(:booking) do
      Booking.create!(
        business: business,
        bookable_service: bookable_service,
        customer_name: "Ahmed Ali",
        customer_phone: "777777777",
        customer_email: "ahmed@example.com",
        start_at: 1.day.from_now,
        end_at: 1.day.from_now + 30.minutes,
        status: :pending
      )
    end

    it "sends owner notification email" do
      expect {
        described_class.call(booking: booking)
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it "returns success result" do
      result = described_class.call(booking: booking)

      expect(result).to be_success
      expect(result.errors).to be_empty
    end

    it "returns failure when booking is nil" do
      result = described_class.call(booking: nil)

      expect(result).not_to be_success
      expect(result.errors).to include("Booking is required")
    end

    it "returns failure when booking is not persisted" do
      new_booking = Booking.new(
        business: business,
        bookable_service: bookable_service,
        customer_name: "Ahmed Ali",
        customer_phone: "777777777",
        start_at: 1.day.from_now,
        end_at: 1.day.from_now + 30.minutes,
        status: :pending
      )

      result = described_class.call(booking: new_booking)

      expect(result).not_to be_success
      expect(result.errors).to include("Booking must be persisted")
    end
  end
end
