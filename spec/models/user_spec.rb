require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { should have_many(:businesses).dependent(:destroy) }
  end

  describe "validations" do
    subject { described_class.new(full_name: "Osama Yeslam", email: "osama@example.com", password: "password123") }

    it { should validate_presence_of(:full_name) }
    it { should validate_length_of(:full_name).is_at_most(100) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_length_of(:email).is_at_most(255) }

    it "is invalid with invalid email format" do
      user = described_class.new(
        full_name: "Osama",
        email: "invalid-email",
        password: "password123"
      )

      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end
  end

  describe "normalization" do
    it "normalizes email before saving" do
      user = described_class.create!(
        full_name: "Osama Yeslam",
        email: "  OSAMA@EXAMPLE.COM  ",
        password: "password123"
      )

      expect(user.email).to eq("osama@example.com")
    end
  end
end
