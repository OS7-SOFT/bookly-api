require "rails_helper"

RSpec.describe "Api::V1::BookableServices", type: :request do
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
    Business.create!(user: user, name: "Bookly Center", is_active: true)
  end

  let!(:another_business) do
    Business.create!(user: another_user, name: "Another Business", is_active: true)
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

  let!(:another_service) do
    BookableService.create!(
      business: another_business,
      name: "Another Service",
      duration_minutes: 30,
      price: 10,
      is_active: true
    )
  end

  describe "GET index (public)" do
    it "returns services without authentication" do
      get "/api/v1/businesses/#{business.id}/bookable_services"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(true)
      expect(json["data"].first["name"]).to eq("Consultation")
    end
  end

  describe "POST create" do
    it "creates service for owner" do
      expect {
        post "/api/v1/businesses/#{business.id}/bookable_services",
             params: {
               bookable_service: {
                 name: "New Service",
                 duration_minutes: 45,
                 price: 30
               }
             },
             headers: auth_headers
      }.to change(BookableService, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "returns unauthorized without token" do
      post "/api/v1/businesses/#{business.id}/bookable_services",
           params: { bookable_service: { name: "Test", duration_minutes: 30 } }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns forbidden when creating in another business" do
      post "/api/v1/businesses/#{another_business.id}/bookable_services",
           params: { bookable_service: { name: "Hack", duration_minutes: 30 } },
           headers: auth_headers

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH update" do
    it "updates owned service" do
      patch "/api/v1/bookable_services/#{bookable_service.id}",
            params: { bookable_service: { name: "Updated" } },
            headers: auth_headers

      expect(response).to have_http_status(:ok)

      expect(bookable_service.reload.name).to eq("Updated")
    end

    it "returns forbidden when updating another user's service" do
      patch "/api/v1/bookable_services/#{another_service.id}",
            params: { bookable_service: { name: "Hack" } },
            headers: auth_headers

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE destroy" do
    it "deletes owned service" do
      expect {
        delete "/api/v1/bookable_services/#{bookable_service.id}", headers: auth_headers
      }.to change(BookableService, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it "returns forbidden when deleting another user's service" do
      delete "/api/v1/bookable_services/#{another_service.id}", headers: auth_headers

      expect(response).to have_http_status(:forbidden)
    end
  end
end
