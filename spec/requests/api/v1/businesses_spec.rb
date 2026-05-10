require "rails_helper"

RSpec.describe "Api::V1::Businesses", type: :request do
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
    {
      "Authorization" => "Bearer #{token}"
    }
  end

  let(:another_auth_headers) do
    {
      "Authorization" => "Bearer #{another_token}"
    }
  end

  let!(:business) do
    Business.create!(
      user: user,
      name: "Bookly Center",
      description: "Consulting center",
      phone: "777777777",
      email: "info@example.com",
      address: "Aden - Yemen",
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

  describe "GET /api/v1/businesses" do
    it "returns current user's businesses" do
      get "/api/v1/businesses", headers: auth_headers

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(true)
      expect(json["data"]).to be_an(Array)
      expect(json["data"].length).to eq(1)
      expect(json["data"].first["id"]).to eq(business.id)
      expect(json["data"].first["name"]).to eq("Bookly Center")
    end

    it "does not return other users businesses" do
      get "/api/v1/businesses", headers: auth_headers

      json = JSON.parse(response.body)

      business_ids = json["data"].map { |item| item["id"] }

      expect(business_ids).to include(business.id)
      expect(business_ids).not_to include(another_business.id)
    end

    it "returns unauthorized without token" do
      get "/api/v1/businesses"

      expect(response).to have_http_status(:unauthorized)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Unauthorized")
    end

    it "returns unauthorized with invalid token" do
      get "/api/v1/businesses", headers: {
        "Authorization" => "Bearer invalid-token"
      }

      expect(response).to have_http_status(:unauthorized)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Unauthorized")
    end
  end

  describe "GET /api/v1/businesses/:id" do
    it "returns business details without authentication" do
      get "/api/v1/businesses/#{business.id}"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(true)
      expect(json["data"]["id"]).to eq(business.id)
      expect(json["data"]["name"]).to eq("Bookly Center")
    end

    it "returns not found when business does not exist" do
      get "/api/v1/businesses/999999"

      expect(response).to have_http_status(:not_found)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Resource not found")
    end
  end

  describe "POST /api/v1/businesses" do
    it "creates business for current user" do
      params = {
        business: {
          name: "New Business",
          description: "New description",
          phone: "711111111",
          email: "new@example.com",
          address: "Aden",
          is_active: true
        }
      }

      expect {
        post "/api/v1/businesses", params: params, headers: auth_headers
      }.to change(Business, :count).by(1)

      expect(response).to have_http_status(:created)

      json = JSON.parse(response.body)

      created_business = Business.last

      expect(json["success"]).to eq(true)
      expect(json["message"]).to eq("Business created successfully")
      expect(json["data"]["name"]).to eq("New Business")
      expect(created_business.user_id).to eq(user.id)
    end

    it "ignores user_id from params and uses current user" do
      params = {
        business: {
          user_id: another_user.id,
          name: "Secure Business"
        }
      }

      post "/api/v1/businesses", params: params, headers: auth_headers

      expect(response).to have_http_status(:created)

      created_business = Business.last

      expect(created_business.user_id).to eq(user.id)
      expect(created_business.user_id).not_to eq(another_user.id)
    end

    it "returns unauthorized without token" do
      post "/api/v1/businesses", params: {
        business: {
          name: "New Business"
        }
      }

      expect(response).to have_http_status(:unauthorized)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Unauthorized")
    end

    it "returns validation errors" do
      params = {
        business: {
          name: ""
        }
      }

      post "/api/v1/businesses", params: params, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["errors"]).to include("Name can't be blank")
    end
  end

  describe "PATCH /api/v1/businesses/:id" do
    it "updates owned business" do
      patch "/api/v1/businesses/#{business.id}",
            params: {
              business: {
                name: "Updated Business"
              }
            },
            headers: auth_headers

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(true)
      expect(json["message"]).to eq("Business updated successfully")
      expect(json["data"]["name"]).to eq("Updated Business")
    end

    it "returns forbidden when updating another user's business" do
      patch "/api/v1/businesses/#{another_business.id}",
            params: {
              business: {
                name: "Hacked Business"
              }
            },
            headers: auth_headers

      expect(response).to have_http_status(:forbidden)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Forbidden")
      expect(another_business.reload.name).to eq("Another Business")
    end

    it "returns unauthorized without token" do
      patch "/api/v1/businesses/#{business.id}", params: {
        business: {
          name: "Updated Business"
        }
      }

      expect(response).to have_http_status(:unauthorized)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Unauthorized")
    end
  end
end
