require "rails_helper"

RSpec.describe "Api::V1::Bookings", type: :request do
  let!(:user) do
    User.create!(
      full_name: "Owner",
      email: "owner@example.com",
      password: "password123"
    )
  end

  let!(:another_user) do
    User.create!(
      full_name: "Another Owner",
      email: "another@example.com",
      password: "password123"
    )
  end

  let(:token) { JsonWebToken.encode({ user_id: user.id }) }
  let(:another_token) { JsonWebToken.encode({ user_id: another_user.id }) }

  let(:auth_headers) do
    { "Authorization" => "Bearer #{token}" }
  end

  let(:another_auth_headers) do
    { "Authorization" => "Bearer #{another_token}" }
  end

  let!(:business) do
    Business.create!(
      user: user,
      name: "Bookly Center",
      is_active: true
    )
  end

  let!(:another_business) do
    Business.create!(
      user: another_user,
      name: "Another Business",
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

  let!(:another_bookable_service) do
    BookableService.create!(
      business: another_business,
      name: "Another Consultation",
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

  let(:start_at) do
    Time.zone.local(next_sunday.year, next_sunday.month, next_sunday.day, 10, 0, 0)
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

  let!(:another_working_hour) do
    WorkingHour.create!(
      business: another_business,
      day_of_week: next_sunday.strftime("%A").downcase,
      start_time: "09:00",
      end_time: "17:00",
      is_closed: false
    )
  end

  let!(:booking) do
    Booking.create!(
      business: business,
      bookable_service: bookable_service,
      customer_name: "Ahmed Ali",
      customer_phone: "777777777",
      customer_email: "ahmed@example.com",
      start_at: start_at,
      end_at: start_at + 30.minutes,
      status: :confirmed,
      notes: "Existing booking"
    )
  end

  let!(:another_booking) do
    Booking.create!(
      business: another_business,
      bookable_service: another_bookable_service,
      customer_name: "Other Customer",
      customer_phone: "711111111",
      customer_email: "other@example.com",
      start_at: start_at,
      end_at: start_at + 30.minutes,
      status: :confirmed,
      notes: "Other booking"
    )
  end

  describe "GET /api/v1/businesses/:business_id/bookings" do
    it "returns bookings for owned business" do
      get "/api/v1/businesses/#{business.id}/bookings", headers: auth_headers

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(true)
      expect(json["data"]).to be_an(Array)
      expect(json["data"].first["customer_name"]).to eq("Ahmed Ali")
    end

    it "returns unauthorized without token" do
      get "/api/v1/businesses/#{business.id}/bookings"

      expect(response).to have_http_status(:unauthorized)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Unauthorized")
    end

    it "returns forbidden for another user's business" do
      get "/api/v1/businesses/#{another_business.id}/bookings", headers: auth_headers

      expect(response).to have_http_status(:forbidden)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Forbidden")
    end

    it "filters bookings by status" do
      get "/api/v1/businesses/#{business.id}/bookings",
          params: { status: "confirmed" },
          headers: auth_headers

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["data"].length).to eq(1)
      expect(json["data"].first["status"]).to eq("confirmed")
    end

    it "filters bookings by customer phone" do
      get "/api/v1/businesses/#{business.id}/bookings",
          params: { customer_phone: "777777777" },
          headers: auth_headers

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["data"].length).to eq(1)
      expect(json["data"].first["customer_phone"]).to eq("777777777")
    end
  end

  describe "GET /api/v1/bookings/:id" do
    it "returns owned booking details" do
      get "/api/v1/bookings/#{booking.id}", headers: auth_headers

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(true)
      expect(json["data"]["id"]).to eq(booking.id)
      expect(json["data"]["customer_name"]).to eq("Ahmed Ali")
    end

    it "returns unauthorized without token" do
      get "/api/v1/bookings/#{booking.id}"

      expect(response).to have_http_status(:unauthorized)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Unauthorized")
    end

    it "returns forbidden for another user's booking" do
      get "/api/v1/bookings/#{another_booking.id}", headers: auth_headers

      expect(response).to have_http_status(:forbidden)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Forbidden")
    end

    it "returns not found when booking does not exist" do
      get "/api/v1/bookings/999999", headers: auth_headers

      expect(response).to have_http_status(:not_found)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Resource not found")
    end
  end

  describe "POST /api/v1/businesses/:business_id/bookings" do
    it "creates booking without authentication" do
      new_start_at = start_at + 30.minutes

      params = {
        booking: {
          bookable_service_id: bookable_service.id,
          customer_name: "Mohammed Ali",
          customer_phone: "711111111",
          customer_email: "mohammed@example.com",
          start_at: new_start_at.iso8601,
          notes: "New booking"
        }
      }

      expect {
        post "/api/v1/businesses/#{business.id}/bookings", params: params
      }.to change(Booking, :count).by(1)

      expect(response).to have_http_status(:created)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(true)
      expect(json["message"]).to eq("Booking created successfully")
      expect(json["data"]["customer_name"]).to eq("Mohammed Ali")
      expect(json["data"]["status"]).to eq("pending")
    end

    it "returns error when booking conflicts with existing booking" do
      params = {
        booking: {
          bookable_service_id: bookable_service.id,
          customer_name: "Conflict Customer",
          customer_phone: "722222222",
          customer_email: "conflict@example.com",
          start_at: start_at.iso8601,
          notes: "Conflict booking"
        }
      }

      expect {
        post "/api/v1/businesses/#{business.id}/bookings", params: params
      }.not_to change(Booking, :count)

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Booking could not be created")
      expect(json["errors"]).to include("Selected time is already booked")
    end
  end

  describe "PATCH /api/v1/bookings/:id/confirm" do
    it "confirms owned pending booking" do
      booking.update!(status: :pending)

      patch "/api/v1/bookings/#{booking.id}/confirm", headers: auth_headers

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(true)
      expect(json["message"]).to eq("Booking confirmed successfully")
      expect(json["data"]["status"]).to eq("confirmed")
    end

    it "returns unauthorized without token" do
      patch "/api/v1/bookings/#{booking.id}/confirm"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns forbidden for another user's booking" do
      patch "/api/v1/bookings/#{another_booking.id}/confirm", headers: auth_headers

      expect(response).to have_http_status(:forbidden)
    end

    it "returns error when booking cannot be confirmed" do
      booking.update!(status: :cancelled)

      patch "/api/v1/bookings/#{booking.id}/confirm", headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["errors"]).to include("Only pending bookings can be confirmed")
    end
  end

  describe "PATCH /api/v1/bookings/:id/cancel" do
    it "cancels owned confirmed booking" do
      booking.update!(status: :confirmed)

      patch "/api/v1/bookings/#{booking.id}/cancel", headers: auth_headers

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(true)
      expect(json["message"]).to eq("Booking cancelled successfully")
      expect(json["data"]["status"]).to eq("cancelled")
    end

    it "returns forbidden for another user's booking" do
      patch "/api/v1/bookings/#{another_booking.id}/cancel", headers: auth_headers

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/bookings/:id/complete" do
    it "completes owned confirmed booking after it ends" do
      booking.update!(
        status: :confirmed,
        start_at: 1.hour.ago,
        end_at: 30.minutes.ago
      )

      patch "/api/v1/bookings/#{booking.id}/complete", headers: auth_headers

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(true)
      expect(json["message"]).to eq("Booking completed successfully")
      expect(json["data"]["status"]).to eq("completed")
    end

    it "returns forbidden for another user's booking" do
      patch "/api/v1/bookings/#{another_booking.id}/complete", headers: auth_headers

      expect(response).to have_http_status(:forbidden)
    end

    it "returns error when booking has not ended yet" do
      booking.update!(
        status: :confirmed,
        start_at: 10.minutes.ago,
        end_at: 20.minutes.from_now
      )

      patch "/api/v1/bookings/#{booking.id}/complete", headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["errors"]).to include("Booking cannot be completed before it ends")
    end
  end

  describe "PATCH /api/v1/bookings/:id/no_show" do
    it "marks owned booking as no-show after it starts" do
      booking.update!(
        status: :confirmed,
        start_at: 30.minutes.ago,
        end_at: 10.minutes.from_now
      )

      patch "/api/v1/bookings/#{booking.id}/no_show", headers: auth_headers

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(true)
      expect(json["message"]).to eq("Booking marked as no-show successfully")
      expect(json["data"]["status"]).to eq("no_show")
    end

    it "returns forbidden for another user's booking" do
      patch "/api/v1/bookings/#{another_booking.id}/no_show", headers: auth_headers

      expect(response).to have_http_status(:forbidden)
    end

    it "returns error when booking has not started yet" do
      booking.update!(
        status: :confirmed,
        start_at: 1.hour.from_now,
        end_at: 90.minutes.from_now
      )

      patch "/api/v1/bookings/#{booking.id}/no_show", headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["errors"]).to include("Booking cannot be marked as no-show before it starts")
    end
  end
end
