require "rails_helper"

RSpec.describe WorkingHour, type: :model do
  describe "associations" do
    it { should belong_to(:business) }
  end

  describe "enums" do
    it do
      should define_enum_for(:day_of_week).with_values(
        sunday: 0,
        monday: 1,
        tuesday: 2,
        wednesday: 3,
        thursday: 4,
        friday: 5,
        saturday: 6
      )
    end
  end

  describe "validations" do
    let!(:user) { User.create!(full_name: "Owner", email: "owner@example.com", password: "password123") }
    let!(:business) { Business.create!(user: user, name: "Business") }

    subject do
      described_class.new(
        business: business,
        day_of_week: :sunday,
        start_time: "09:00",
        end_time: "17:00",
        is_closed: false
      )
    end

    it { should validate_presence_of(:day_of_week) }

    it "does not allow duplicate day for the same business" do
      described_class.create!(
        business: business,
        day_of_week: :sunday,
        start_time: "09:00",
        end_time: "17:00",
        is_closed: false
      )

      duplicate = described_class.new(
        business: business,
        day_of_week: :sunday,
        start_time: "10:00",
        end_time: "18:00",
        is_closed: false
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:day_of_week]).to be_present
    end

    it "requires start_time when day is not closed" do
      working_hour = described_class.new(
        business: business,
        day_of_week: :monday,
        start_time: nil,
        end_time: "17:00",
        is_closed: false
      )

      expect(working_hour).not_to be_valid
      expect(working_hour.errors[:start_time]).to be_present
    end

    it "requires end_time when day is not closed" do
      working_hour = described_class.new(
        business: business,
        day_of_week: :monday,
        start_time: "09:00",
        end_time: nil,
        is_closed: false
      )

      expect(working_hour).not_to be_valid
      expect(working_hour.errors[:end_time]).to be_present
    end

    it "allows start_time and end_time to be blank when day is closed" do
      working_hour = described_class.new(
        business: business,
        day_of_week: :friday,
        start_time: nil,
        end_time: nil,
        is_closed: true
      )

      expect(working_hour).to be_valid
    end

    it "is invalid when start_time is after end_time" do
      working_hour = described_class.new(
        business: business,
        day_of_week: :tuesday,
        start_time: "18:00",
        end_time: "09:00",
        is_closed: false
      )

      expect(working_hour).not_to be_valid
      expect(working_hour.errors[:start_time]).to be_present
    end
  end
end
