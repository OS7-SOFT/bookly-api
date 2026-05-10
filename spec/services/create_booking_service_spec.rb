require "rails_helper"
require "active_job/test_helper"

RSpec.describe CreateBookingService do
  include ActiveJob::TestHelper
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

    let!(:working_hour) do
      WorkingHour.create!(
        business: business,
        day_of_week: next_sunday.strftime("%A").downcase,
        start_time: "09:00",
        end_time: "17:00",
        is_closed: false
      )
    end

    let(:next_sunday) do
      date = Date.current
      date += 1.day until date.sunday? && date > Date.current
      date
    end

    let(:start_at) do
      Time.zone.local(next_sunday.year, next_sunday.month, next_sunday.day, 10, 0, 0)
    end

    let(:valid_params) do
      {
        business_id: business.id,
        bookable_service_id: bookable_service.id,
        customer_name: "Ahmed Ali",
        customer_phone: "777777777",
        customer_email: "ahmed@example.com",
        start_at: start_at.iso8601,
        notes: "Consultation about e-commerce project"
      }
    end

    context "when params are valid" do
      it "creates a booking successfully" do
        result = described_class.call(**valid_params)

        expect(result).to be_success
        expect(result.booking).to be_persisted
        expect(result.errors).to be_empty
      end

      it "sets booking status to pending" do
        result = described_class.call(**valid_params)

        expect(result.booking.status).to eq("pending")
      end

      it "calculates end_at from service duration" do
        result = described_class.call(**valid_params)

        expect(result.booking.start_at.to_i).to eq(start_at.to_i)
        expect(result.booking.end_at.to_i).to eq((start_at + 30.minutes).to_i)
      end

      it "enqueues new booking notification job" do
        clear_enqueued_jobs
        expect {
          described_class.call(**valid_params)
        }.to have_enqueued_job(NewBookingNotificationJob)
      end
    end

    context "when business does not exist" do
      it "returns failure" do
        result = described_class.call(**valid_params.merge(business_id: 999_999))

        expect(result).not_to be_success
        expect(result.booking).to be_nil
        expect(result.errors).to include("Business not found")
      end
    end

    context "when business is inactive" do
      it "returns failure" do
        business.update!(is_active: false)

        result = described_class.call(**valid_params)

        expect(result).not_to be_success
        expect(result.errors).to include("Business is not active")
      end
    end

    context "when bookable service does not exist" do
      it "returns failure" do
        result = described_class.call(**valid_params.merge(bookable_service_id: 999_999))

        expect(result).not_to be_success
        expect(result.booking).to be_nil
        expect(result.errors).to include("Bookable service not found")
      end
    end

    context "when bookable service is inactive" do
      it "returns failure" do
        bookable_service.update!(is_active: false)

        result = described_class.call(**valid_params)

        expect(result).not_to be_success
        expect(result.errors).to include("Bookable service is not active")
      end
    end

    context "when bookable service belongs to another business" do
      it "returns failure" do
        another_business = Business.create!(
          user: user,
          name: "Another Business",
          is_active: true
        )

        another_service = BookableService.create!(
          business: another_business,
          name: "Another Consultation",
          duration_minutes: 30,
          price: 10,
          is_active: true
        )

        result = described_class.call(
          **valid_params.merge(bookable_service_id: another_service.id)
        )

        expect(result).not_to be_success
        expect(result.errors).to include("Bookable service does not belong to this business")
      end
    end

    context "when start_at is invalid" do
      it "returns failure" do
        result = described_class.call(**valid_params.merge(start_at: "wrong-date"))

        expect(result).not_to be_success
        expect(result.errors).to include("Start at is invalid")
      end
    end

    context "when booking time is in the past" do
      it "returns failure" do
        past_time = 1.day.ago

        result = described_class.call(**valid_params.merge(start_at: past_time.iso8601))

        expect(result).not_to be_success
        expect(result.errors).to include("Booking time must be in the future")
      end
    end

    context "when working hours are not configured" do
      it "returns failure" do
        working_hour.destroy!

        result = described_class.call(**valid_params)

        expect(result).not_to be_success
        expect(result.errors).to include("Working hours are not configured for this day")
      end
    end

    context "when business is closed on that day" do
      it "returns failure" do
        working_hour.update!(
          is_closed: true,
          start_time: nil,
          end_time: nil
        )

        result = described_class.call(**valid_params)

        expect(result).not_to be_success
        expect(result.errors).to include("Business is closed on this day")
      end
    end

    context "when booking starts before working hours" do
      it "returns failure" do
        early_start_at = Time.zone.local(
          next_sunday.year,
          next_sunday.month,
          next_sunday.day,
          8,
          30,
          0
        )

        result = described_class.call(
          **valid_params.merge(start_at: early_start_at.iso8601)
        )

        expect(result).not_to be_success
        expect(result.errors).to include("Booking time is outside working hours")
      end
    end

    context "when booking ends after working hours" do
      it "returns failure" do
        late_start_at = Time.zone.local(
          next_sunday.year,
          next_sunday.month,
          next_sunday.day,
          16,
          45,
          0
        )

        result = described_class.call(
          **valid_params.merge(start_at: late_start_at.iso8601)
        )

        expect(result).not_to be_success
        expect(result.errors).to include("Booking time is outside working hours")
      end
    end

    context "when there is an exact conflicting booking" do
      it "returns failure" do
        Booking.create!(
          business: business,
          bookable_service: bookable_service,
          customer_name: "Old Customer",
          customer_phone: "111111111",
          start_at: start_at,
          end_at: start_at + 30.minutes,
          status: :confirmed
        )

        result = described_class.call(**valid_params)

        expect(result).not_to be_success
        expect(result.errors).to include("Selected time is already booked")
      end
    end

    context "when there is an overlapping booking" do
      it "returns failure" do
        Booking.create!(
          business: business,
          bookable_service: bookable_service,
          customer_name: "Old Customer",
          customer_phone: "111111111",
          start_at: start_at - 15.minutes,
          end_at: start_at + 15.minutes,
          status: :confirmed
        )

        result = described_class.call(**valid_params)

        expect(result).not_to be_success
        expect(result.errors).to include("Selected time is already booked")
      end
    end

    context "when previous booking ends exactly at new start time" do
      it "creates booking successfully" do
        Booking.create!(
          business: business,
          bookable_service: bookable_service,
          customer_name: "Old Customer",
          customer_phone: "111111111",
          start_at: start_at - 30.minutes,
          end_at: start_at,
          status: :confirmed
        )

        result = described_class.call(**valid_params)

        expect(result).to be_success
        expect(result.booking).to be_persisted
      end
    end

    context "when existing booking is cancelled" do
      it "ignores cancelled booking conflict" do
        Booking.create!(
          business: business,
          bookable_service: bookable_service,
          customer_name: "Cancelled Customer",
          customer_phone: "222222222",
          start_at: start_at,
          end_at: start_at + 30.minutes,
          status: :cancelled
        )

        result = described_class.call(**valid_params)

        expect(result).to be_success
        expect(result.booking).to be_persisted
      end
    end

    context "when customer data is invalid" do
      it "returns model validation errors" do
        result = described_class.call(
          **valid_params.merge(customer_name: "", customer_phone: "")
        )

        expect(result).not_to be_success
        expect(result.errors).to include("Customer name can't be blank")
        expect(result.errors).to include("Customer phone can't be blank")
      end
    end
  end
end
