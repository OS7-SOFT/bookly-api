require "rails_helper"

RSpec.describe BookingStatusService do
  describe ".call" do
    let!(:user) do
      User.create!(
        full_name: "Owner",
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

    def create_booking(status:, start_at:, end_at:)
      Booking.create!(
        business: business,
        bookable_service: bookable_service,
        customer_name: "Ahmed Ali",
        customer_phone: "777777777",
        customer_email: "ahmed@example.com",
        start_at: start_at,
        end_at: end_at,
        status: status
      )
    end

    context "when action is confirm" do
      it "confirms a pending booking" do
        booking = create_booking(
          status: :pending,
          start_at: 1.day.from_now,
          end_at: 1.day.from_now + 30.minutes
        )

        result = described_class.call(booking: booking, action: :confirm)

        expect(result).to be_success
        expect(result.booking.status).to eq("confirmed")
        expect(result.errors).to be_empty
      end

      it "does not confirm a cancelled booking" do
        booking = create_booking(
          status: :cancelled,
          start_at: 1.day.from_now,
          end_at: 1.day.from_now + 30.minutes
        )

        result = described_class.call(booking: booking, action: :confirm)

        expect(result).not_to be_success
        expect(result.errors).to include("Only pending bookings can be confirmed")
        expect(booking.reload.status).to eq("cancelled")
      end
    end

    context "when action is cancel" do
      it "cancels a pending booking" do
        booking = create_booking(
          status: :pending,
          start_at: 1.day.from_now,
          end_at: 1.day.from_now + 30.minutes
        )

        result = described_class.call(booking: booking, action: :cancel)

        expect(result).to be_success
        expect(result.booking.status).to eq("cancelled")
      end

      it "cancels a confirmed booking" do
        booking = create_booking(
          status: :confirmed,
          start_at: 1.day.from_now,
          end_at: 1.day.from_now + 30.minutes
        )

        result = described_class.call(booking: booking, action: :cancel)

        expect(result).to be_success
        expect(result.booking.status).to eq("cancelled")
      end

      it "does not cancel a completed booking" do
        booking = create_booking(
          status: :completed,
          start_at: 1.day.ago,
          end_at: 1.day.ago + 30.minutes
        )

        result = described_class.call(booking: booking, action: :cancel)

        expect(result).not_to be_success
        expect(result.errors).to include("Only pending or confirmed bookings can be cancelled")
        expect(booking.reload.status).to eq("completed")
      end
    end

    context "when action is complete" do
      it "completes a confirmed booking after it ends" do
        booking = create_booking(
          status: :confirmed,
          start_at: 1.hour.ago,
          end_at: 30.minutes.ago
        )

        result = described_class.call(booking: booking, action: :complete)

        expect(result).to be_success
        expect(result.booking.status).to eq("completed")
      end

      it "does not complete a pending booking" do
        booking = create_booking(
          status: :pending,
          start_at: 1.hour.ago,
          end_at: 30.minutes.ago
        )

        result = described_class.call(booking: booking, action: :complete)

        expect(result).not_to be_success
        expect(result.errors).to include("Only confirmed bookings can be completed")
        expect(booking.reload.status).to eq("pending")
      end

      it "does not complete a confirmed booking before it ends" do
        booking = create_booking(
          status: :confirmed,
          start_at: 10.minutes.ago,
          end_at: 20.minutes.from_now
        )

        result = described_class.call(booking: booking, action: :complete)

        expect(result).not_to be_success
        expect(result.errors).to include("Booking cannot be completed before it ends")
        expect(booking.reload.status).to eq("confirmed")
      end
    end

    context "when action is mark_as_no_show" do
      it "marks a pending booking as no-show after it starts" do
        booking = create_booking(
          status: :pending,
          start_at: 30.minutes.ago,
          end_at: 10.minutes.from_now
        )

        result = described_class.call(booking: booking, action: :mark_as_no_show)

        expect(result).to be_success
        expect(result.booking.status).to eq("no_show")
      end

      it "marks a confirmed booking as no-show after it starts" do
        booking = create_booking(
          status: :confirmed,
          start_at: 30.minutes.ago,
          end_at: 10.minutes.from_now
        )

        result = described_class.call(booking: booking, action: :mark_as_no_show)

        expect(result).to be_success
        expect(result.booking.status).to eq("no_show")
      end

      it "does not mark a future booking as no-show" do
        booking = create_booking(
          status: :confirmed,
          start_at: 1.hour.from_now,
          end_at: 90.minutes.from_now
        )

        result = described_class.call(booking: booking, action: :mark_as_no_show)

        expect(result).not_to be_success
        expect(result.errors).to include("Booking cannot be marked as no-show before it starts")
        expect(booking.reload.status).to eq("confirmed")
      end
    end

    context "when action is invalid" do
      it "returns failure" do
        booking = create_booking(
          status: :pending,
          start_at: 1.day.from_now,
          end_at: 1.day.from_now + 30.minutes
        )

        result = described_class.call(booking: booking, action: :wrong_action)

        expect(result).not_to be_success
        expect(result.errors).to include("Invalid booking status action")
        expect(booking.reload.status).to eq("pending")
      end
    end
  end
end
