require "rails_helper"

RSpec.describe Booking, type: :model do
  describe "associations" do
    it { should belong_to(:business) }
    it { should belong_to(:bookable_service) }
  end

  describe "enums" do
    it do
      should define_enum_for(:status).with_values(
        pending: 0,
        confirmed: 1,
        cancelled: 2,
        completed: 3,
        no_show: 4
      )
    end
  end

  describe "validations" do
    let!(:user) { User.create!(full_name: "Owner", email: "owner@example.com", password: "password123") }
    let!(:business) { Business.create!(user: user, name: "Business") }

    let!(:bookable_service) do
      BookableService.create!(
        business: business,
        name: "Consultation",
        duration_minutes: 30,
        price: 20
      )
    end

    subject do
      described_class.new(
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

    it { should validate_presence_of(:customer_name) }
    it { should validate_length_of(:customer_name).is_at_most(100) }

    it { should validate_presence_of(:customer_phone) }
    it { should validate_length_of(:customer_phone).is_at_most(30) }

    it { should validate_presence_of(:start_at) }
    it { should validate_presence_of(:end_at) }
    it { should validate_presence_of(:status) }

    it { should validate_length_of(:notes).is_at_most(1_000) }

    it "is invalid with invalid customer email format" do
      booking = described_class.new(
        business: business,
        bookable_service: bookable_service,
        customer_name: "Ahmed",
        customer_phone: "777777777",
        customer_email: "wrong-email",
        start_at: 1.day.from_now,
        end_at: 1.day.from_now + 30.minutes,
        status: :pending
      )

      expect(booking).not_to be_valid
      expect(booking.errors[:customer_email]).to be_present
    end

    it "is invalid when end_at is before start_at" do
      booking = described_class.new(
        business: business,
        bookable_service: bookable_service,
        customer_name: "Ahmed",
        customer_phone: "777777777",
        start_at: 1.day.from_now,
        end_at: 1.day.from_now - 30.minutes,
        status: :pending
      )

      expect(booking).not_to be_valid
      expect(booking.errors[:end_at]).to be_present
    end

    it "is invalid when end_at equals start_at" do
      time = 1.day.from_now

      booking = described_class.new(
        business: business,
        bookable_service: bookable_service,
        customer_name: "Ahmed",
        customer_phone: "777777777",
        start_at: time,
        end_at: time,
        status: :pending
      )

      expect(booking).not_to be_valid
      expect(booking.errors[:end_at]).to be_present
    end

    it "is invalid when bookable service does not belong to the same business" do
      another_user = User.create!(
        full_name: "Another Owner",
        email: "another@example.com",
        password: "password123"
      )

      another_business = Business.create!(
        user: another_user,
        name: "Another Business"
      )

      another_service = BookableService.create!(
        business: another_business,
        name: "Another Service",
        duration_minutes: 30,
        price: 10
      )

      booking = described_class.new(
        business: business,
        bookable_service: another_service,
        customer_name: "Ahmed",
        customer_phone: "777777777",
        start_at: 1.day.from_now,
        end_at: 1.day.from_now + 30.minutes,
        status: :pending
      )

      expect(booking).not_to be_valid
      expect(booking.errors[:bookable_service]).to be_present
    end
  end

  describe "normalization" do
    let!(:user) { User.create!(full_name: "Owner", email: "owner@example.com", password: "password123") }
    let!(:business) { Business.create!(user: user, name: "Business") }

    let!(:bookable_service) do
      BookableService.create!(
        business: business,
        name: "Consultation",
        duration_minutes: 30,
        price: 20
      )
    end

    it "normalizes customer email and phone" do
      booking = described_class.create!(
        business: business,
        bookable_service: bookable_service,
        customer_name: "Ahmed",
        customer_phone: "  777777777  ",
        customer_email: "  AHMED@EXAMPLE.COM  ",
        start_at: 1.day.from_now,
        end_at: 1.day.from_now + 30.minutes,
        status: :pending
      )

      expect(booking.customer_phone).to eq("777777777")
      expect(booking.customer_email).to eq("ahmed@example.com")
    end
  end

  describe "scopes" do
    let!(:user) { User.create!(full_name: "Owner", email: "owner@example.com", password: "password123") }
    let!(:business) { Business.create!(user: user, name: "Business") }

    let!(:bookable_service) do
      BookableService.create!(
        business: business,
        name: "Consultation",
        duration_minutes: 30,
        price: 20
      )
    end

    let!(:pending_booking) do
      described_class.create!(
        business: business,
        bookable_service: bookable_service,
        customer_name: "Pending Customer",
        customer_phone: "111",
        start_at: 2.days.from_now,
        end_at: 2.days.from_now + 30.minutes,
        status: :pending
      )
    end

    let!(:cancelled_booking) do
      described_class.create!(
        business: business,
        bookable_service: bookable_service,
        customer_name: "Cancelled Customer",
        customer_phone: "222",
        start_at: 3.days.from_now,
        end_at: 3.days.from_now + 30.minutes,
        status: :cancelled
      )
    end

    let!(:past_booking) do
      described_class.create!(
        business: business,
        bookable_service: bookable_service,
        customer_name: "Past Customer",
        customer_phone: "333",
        start_at: 2.days.ago,
        end_at: 2.days.ago + 30.minutes,
        status: :completed
      )
    end

    it "returns bookings active for conflict" do
      expect(described_class.active_for_conflict).to include(pending_booking)
      expect(described_class.active_for_conflict).not_to include(cancelled_booking)
    end

    it "returns upcoming bookings" do
      expect(described_class.upcoming).to include(pending_booking)
      expect(described_class.upcoming).not_to include(past_booking)
    end

    it "returns past bookings" do
      expect(described_class.past).to include(past_booking)
      expect(described_class.past).not_to include(pending_booking)
    end

    it "returns bookings for a specific date" do
      date = pending_booking.start_at.to_date

      expect(described_class.for_date(date)).to include(pending_booking)
      expect(described_class.for_date(date)).not_to include(past_booking)
    end
  end
end
