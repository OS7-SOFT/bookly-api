require "rails_helper"

RSpec.describe BookableService, type: :model do
  describe "associations" do
    it { should belong_to(:business) }
    it { should have_many(:bookings).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(150) }

    it { should validate_length_of(:description).is_at_most(1_000) }

    it { should validate_presence_of(:duration_minutes) }

    it do
      should validate_numericality_of(:duration_minutes)
        .only_integer
        .is_greater_than(0)
        .is_less_than_or_equal_to(1_440)
    end

    it { should validate_presence_of(:price) }

    it do
      should validate_numericality_of(:price)
        .is_greater_than_or_equal_to(0)
    end
  end

  describe "scopes" do
    let!(:user) { User.create!(full_name: "Owner", email: "owner@example.com", password: "password123") }
    let!(:business) { Business.create!(user: user, name: "Business") }

    let!(:active_service) do
      described_class.create!(
        business: business,
        name: "Active Service",
        duration_minutes: 30,
        price: 20,
        is_active: true
      )
    end

    let!(:inactive_service) do
      described_class.create!(
        business: business,
        name: "Inactive Service",
        duration_minutes: 30,
        price: 20,
        is_active: false
      )
    end

    it "returns only active services" do
      expect(described_class.active).to include(active_service)
      expect(described_class.active).not_to include(inactive_service)
    end
  end
end
