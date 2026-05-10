require "rails_helper"

RSpec.describe Business, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:bookable_services).dependent(:destroy) }
    it { should have_many(:working_hours).dependent(:destroy) }
    it { should have_many(:bookings).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(150) }
    it { should validate_length_of(:description).is_at_most(1_000) }
    it { should validate_length_of(:phone).is_at_most(30) }
    it { should validate_length_of(:address).is_at_most(255) }

    it "is invalid with invalid email format" do
      business = described_class.new(
        name: "Bookly Center",
        email: "wrong-email"
      )

      expect(business).not_to be_valid
      expect(business.errors[:email]).to be_present
    end
  end

  describe "scopes" do
    let!(:user) { User.create!(full_name: "Owner", email: "owner@example.com", password: "password123") }

    let!(:active_business) do
      described_class.create!(
        user: user,
        name: "Active Business",
        is_active: true
      )
    end

    let!(:inactive_business) do
      described_class.create!(
        user: user,
        name: "Inactive Business",
        is_active: false
      )
    end

    it "returns only active businesses" do
      expect(described_class.active).to include(active_business)
      expect(described_class.active).not_to include(inactive_business)
    end
  end
end
