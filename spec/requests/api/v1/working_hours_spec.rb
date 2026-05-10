require "rails_helper"

RSpec.describe "Api::V1::WorkingHours", type: :request do
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

  let!(:working_hour) do
    WorkingHour.create!(
      business: business,
      day_of_week: :sunday,
      start_time: "09:00",
      end_time: "17:00",
      is_closed: false
    )
  end

  let!(:another_working_hour) do
    WorkingHour.create!(
      business: another_business,
      day_of_week: :monday,
      start_time: "10:00",
      end_time: "18:00",
      is_closed: false
    )
  end

  describe "GET /api/v1/businesses/:business_id/working_hours" do
    it "returns working hours without authentication" do
      get "/api/v1/businesses/#{business.id}/working_hours"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(true)
      expect(json["data"]).to be_an(Array)
      expect(json["data"].first["day_of_week"]).to eq("sunday")
    end
  end

  describe "GET /api/v1/working_hours/:id" do
    it "returns working hour without authentication" do
      get "/api/v1/working_hours/#{working_hour.id}"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(true)
      expect(json["data"]["id"]).to eq(working_hour.id)
      expect(json["data"]["start_time"]).to eq("09:00")
      expect(json["data"]["end_time"]).to eq("17:00")
    end
  end

  describe "POST /api/v1/businesses/:business_id/working_hours" do
    it "creates working hour for owner" do
      params = {
        working_hour: {
          day_of_week: "tuesday",
          start_time: "08:00",
          end_time: "16:00",
          is_closed: false
        }
      }

      expect {
        post "/api/v1/businesses/#{business.id}/working_hours",
             params: params,
             headers: auth_headers
      }.to change(WorkingHour, :count).by(1)

      expect(response).to have_http_status(:created)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(true)
      expect(json["message"]).to eq("Working hour created successfully")
      expect(json["data"]["day_of_week"]).to eq("tuesday")
    end

    it "returns unauthorized without token" do
      post "/api/v1/businesses/#{business.id}/working_hours",
           params: {
             working_hour: {
               day_of_week: "wednesday",
               start_time: "09:00",
               end_time: "17:00",
               is_closed: false
             }
           }

      expect(response).to have_http_status(:unauthorized)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Unauthorized")
    end

    it "returns forbidden when creating working hour for another user's business" do
      post "/api/v1/businesses/#{another_business.id}/working_hours",
           params: {
             working_hour: {
               day_of_week: "wednesday",
               start_time: "09:00",
               end_time: "17:00",
               is_closed: false
             }
           },
           headers: auth_headers

      expect(response).to have_http_status(:forbidden)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Forbidden")
    end

    it "returns validation errors" do
      post "/api/v1/businesses/#{business.id}/working_hours",
           params: {
             working_hour: {
               day_of_week: "thursday",
               start_time: "18:00",
               end_time: "09:00",
               is_closed: false
             }
           },
           headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Working hour could not be created")
      expect(json["errors"]).to be_present
    end
  end

  describe "PATCH /api/v1/working_hours/:id" do
    it "updates owned working hour" do
      patch "/api/v1/working_hours/#{working_hour.id}",
            params: {
              working_hour: {
                start_time: "08:00",
                end_time: "16:00"
              }
            },
            headers: auth_headers

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(true)
      expect(json["message"]).to eq("Working hour updated successfully")
      expect(json["data"]["start_time"]).to eq("08:00")
      expect(json["data"]["end_time"]).to eq("16:00")
    end

    it "returns unauthorized without token" do
      patch "/api/v1/working_hours/#{working_hour.id}",
            params: {
              working_hour: {
                start_time: "08:00",
                end_time: "16:00"
              }
            }

      expect(response).to have_http_status(:unauthorized)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Unauthorized")
    end

    it "returns forbidden when updating another user's working hour" do
      patch "/api/v1/working_hours/#{another_working_hour.id}",
            params: {
              working_hour: {
                start_time: "08:00",
                end_time: "16:00"
              }
            },
            headers: auth_headers

      expect(response).to have_http_status(:forbidden)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Forbidden")
      expect(another_working_hour.reload.start_time.strftime("%H:%M")).to eq("10:00")
    end
  end

  describe "DELETE /api/v1/working_hours/:id" do
    it "deletes owned working hour" do
      expect {
        delete "/api/v1/working_hours/#{working_hour.id}",
               headers: auth_headers
      }.to change(WorkingHour, :count).by(-1)

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(true)
      expect(json["message"]).to eq("Working hour deleted successfully")
    end

    it "returns unauthorized without token" do
      delete "/api/v1/working_hours/#{working_hour.id}"

      expect(response).to have_http_status(:unauthorized)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Unauthorized")
    end

    it "returns forbidden when deleting another user's working hour" do
      expect {
        delete "/api/v1/working_hours/#{another_working_hour.id}",
               headers: auth_headers
      }.not_to change(WorkingHour, :count)

      expect(response).to have_http_status(:forbidden)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Forbidden")
    end
  end
end
