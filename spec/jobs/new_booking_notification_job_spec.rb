require "rails_helper"

RSpec.describe NewBookingNotificationJob, type: :job do
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
      start_at: 1.day.from_now,
      end_at: 1.day.from_now + 30.minutes,
      status: :pending
    )
  end

  it "calls new booking notifier" do
    expect(Notifications::NewBookingNotifier)
      .to receive(:call)
      .with(booking: booking)

    described_class.perform_now(booking.id)
  end

  it "sends email when performed" do
    expect {
      described_class.perform_now(booking.id)
    }.to change { ActionMailer::Base.deliveries.count }.by(1)
  end
end
