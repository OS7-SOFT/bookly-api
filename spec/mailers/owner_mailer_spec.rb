require "rails_helper"

RSpec.describe OwnerMailer, type: :mailer do
  describe "#new_booking_notification" do
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
        status: :pending,
        notes: "I need consultation"
      )
    end

    let(:mail) { described_class.new_booking_notification(booking) }

    it "sends email to business owner" do
      expect(mail.to).to eq([ "owner@example.com" ])
    end

    it "has correct subject" do
      expect(mail.subject).to eq("New booking received")
    end

    it "includes booking details in the email body" do
      body = mail.body.encoded

      expect(body).to include("New booking received")
      expect(body).to include("Bookly Center")
      expect(body).to include("Consultation")
      expect(body).to include("Ahmed Ali")
      expect(body).to include("777777777")
      expect(body).to include("ahmed@example.com")
      expect(body).to include("I need consultation")
    end
  end
end
