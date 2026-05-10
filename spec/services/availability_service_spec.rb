require "rails_helper"

RSpec.describe AvailabilityService do
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

    let(:next_sunday) do
      date = Date.current
      date += 1.day until date.sunday? && date > Date.current
      date
    end

    let!(:working_hour) do
      WorkingHour.create!(
        business: business,
        day_of_week: next_sunday.strftime("%A").downcase,
        start_time: "09:00",
        end_time: "11:00",
        is_closed: false
      )
    end

    let(:valid_params) do
      {
        business_id: business.id,
        bookable_service_id: bookable_service.id,
        date: next_sunday.to_s
      }
    end

    context "when params are valid" do
      it "returns available slots" do
        result = described_class.call(**valid_params)

        expect(result).to be_success
        expect(result.data[:available_slots]).to eq([
          "09:00",
          "09:30",
          "10:00",
          "10:30"
        ])
      end
    end

    context "when there is an existing booking" do
      it "excludes booked slots" do
        start_at = Time.zone.local(
          next_sunday.year,
          next_sunday.month,
          next_sunday.day,
          9,
          30,
          0
        )

        Booking.create!(
          business: business,
          bookable_service: bookable_service,
          customer_name: "Ahmed",
          customer_phone: "777777777",
          start_at: start_at,
          end_at: start_at + 30.minutes,
          status: :confirmed
        )

        result = described_class.call(**valid_params)

        expect(result).to be_success
        expect(result.data[:available_slots]).to eq([
          "09:00",
          "10:00",
          "10:30"
        ])
      end
    end

    context "when existing booking is cancelled" do
      it "does not exclude cancelled booking slot" do
        start_at = Time.zone.local(
          next_sunday.year,
          next_sunday.month,
          next_sunday.day,
          9,
          30,
          0
        )

        Booking.create!(
          business: business,
          bookable_service: bookable_service,
          customer_name: "Ahmed",
          customer_phone: "777777777",
          start_at: start_at,
          end_at: start_at + 30.minutes,
          status: :cancelled
        )

        result = described_class.call(**valid_params)

        expect(result).to be_success
        expect(result.data[:available_slots]).to include("09:30")
      end
    end

    context "when service duration is 60 minutes" do
      it "returns only slots that can finish within working hours" do
        bookable_service.update!(duration_minutes: 60)

        result = described_class.call(**valid_params)

        expect(result).to be_success
        expect(result.data[:available_slots]).to eq([
          "09:00",
          "09:30",
          "10:00"
        ])
      end
    end

    context "when business does not exist" do
      it "returns failure" do
        result = described_class.call(
          **valid_params.merge(business_id: 999_999)
        )

        expect(result).not_to be_success
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
        result = described_class.call(
          **valid_params.merge(bookable_service_id: 999_999)
        )

        expect(result).not_to be_success
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
          name: "Another Service",
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

    context "when date is invalid" do
      it "returns failure" do
        result = described_class.call(
          **valid_params.merge(date: "wrong-date")
        )

        expect(result).not_to be_success
        expect(result.errors).to include("Date is invalid")
      end
    end

    context "when working hours are not configured" do
      it "returns empty slots" do
        working_hour.destroy!

        result = described_class.call(**valid_params)

        expect(result).to be_success
        expect(result.data[:available_slots]).to eq([])
      end
    end

    context "when business is closed on that day" do
      it "returns empty slots" do
        working_hour.update!(
          is_closed: true,
          start_time: nil,
          end_time: nil
        )

        result = described_class.call(**valid_params)

        expect(result).to be_success
        expect(result.data[:available_slots]).to eq([])
      end
    end
  end
end
