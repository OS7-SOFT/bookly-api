require "rails_helper"

RSpec.describe "Api::V1::Availability", type: :request do
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

  describe "GET /api/v1/businesses/:id/availability" do
    it "returns available slots" do
      get "/api/v1/businesses/#{business.id}/availability", params: {
        bookable_service_id: bookable_service.id,
        date: next_sunday.to_s
      }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(true)
      expect(json["data"]["date"]).to eq(next_sunday.to_s)
      expect(json["data"]["bookable_service_id"]).to eq(bookable_service.id)
      expect(json["data"]["available_slots"]).to eq([
        "09:00",
        "09:30",
        "10:00",
        "10:30"
      ])
    end

    it "returns error when service does not exist" do
      get "/api/v1/businesses/#{business.id}/availability", params: {
        bookable_service_id: 999_999,
        date: next_sunday.to_s
      }

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["errors"]).to include("Bookable service not found")
    end

    it "returns error when date is invalid" do
      get "/api/v1/businesses/#{business.id}/availability", params: {
        bookable_service_id: bookable_service.id,
        date: "wrong-date"
      }

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["errors"]).to include("Date is invalid")
    end
  end
end
