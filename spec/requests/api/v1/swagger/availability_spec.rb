require "swagger_helper"

RSpec.describe "Availability API", type: :request do
  let!(:user) do
    User.create!(
      full_name: "Owner User",
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

  before do
    WorkingHour.create!(
      business: business,
      day_of_week: next_sunday.strftime("%A").downcase,
      start_time: "09:00",
      end_time: "11:00",
      is_closed: false
    )
  end

  path "/api/v1/businesses/{business_id}/availability" do
    parameter name: :business_id,
              in: :path,
              type: :integer,
              description: "Business ID"

    parameter name: :bookable_service_id,
              in: :query,
              required: true,
              schema: { type: :integer, example: 1 },
              description: "Bookable Service ID"

    parameter name: :date,
              in: :query,
              required: true,
              schema: { type: :string, format: :date, example: "2026-05-10" },
              description: "Date to check availability"

    get "Get available booking slots" do
      tags "Availability"
      produces "application/json"

      response "200", "available slots returned" do
        let(:business_id) { business.id }
        let(:bookable_service_id) { bookable_service.id }
        let(:date) { next_sunday.to_s }

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 data: { "$ref" => "#/components/schemas/Availability" }
               },
               required: [ "success", "data" ]

        run_test!
      end

      response "422", "invalid request or business rule error" do
        let(:business_id) { business.id }
        let(:bookable_service_id) { 999_999 }
        let(:date) { next_sunday.to_s }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end

      response "422", "invalid date" do
        let(:business_id) { business.id }
        let(:bookable_service_id) { bookable_service.id }
        let(:date) { "wrong-date" }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end
    end
  end
end
