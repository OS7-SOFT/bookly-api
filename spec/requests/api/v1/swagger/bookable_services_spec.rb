require "swagger_helper"

RSpec.describe "Bookable Services API", type: :request do
  let!(:user) do
    User.create!(
      full_name: "Owner User",
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

  let(:Authorization) { "Bearer #{JsonWebToken.encode({ user_id: user.id })}" }

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

  path "/api/v1/businesses/{business_id}/bookable_services" do
    parameter name: :business_id,
              in: :path,
              type: :integer,
              description: "Business ID"

    get "List bookable services for a business" do
      tags "Bookable Services"
      produces "application/json"

      response "200", "bookable services returned" do
        let(:business_id) { business.id }

        before do
          BookableService.create!(
            business: business,
            name: "Consultation",
            description: "Software consultation session",
            duration_minutes: 30,
            price: 20,
            is_active: true
          )
        end

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 data: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/BookableService" }
                 }
               },
               required: [ "success", "data" ]

        run_test!
      end

      response "404", "business not found" do
        let(:business_id) { 999_999 }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end
    end

    post "Create a bookable service" do
      tags "Bookable Services"
      consumes "application/json"
      produces "application/json"
      security [ bearerAuth: [] ]

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          bookable_service: {
            type: :object,
            properties: {
              name: { type: :string, example: "Consultation" },
              description: { type: :string, example: "Software consultation session" },
              duration_minutes: { type: :integer, example: 30 },
              price: { type: :number, format: :float, example: 20.0 },
              is_active: { type: :boolean, example: true }
            },
            required: [ "name", "duration_minutes" ]
          }
        },
        required: [ "bookable_service" ]
      }

      response "201", "bookable service created" do
        let(:business_id) { business.id }

        let(:payload) do
          {
            bookable_service: {
              name: "Consultation",
              description: "Software consultation session",
              duration_minutes: 30,
              price: 20,
              is_active: true
            }
          }
        end

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 message: { type: :string, example: "Bookable service created successfully" },
                 data: { "$ref" => "#/components/schemas/BookableService" }
               },
               required: [ "success", "message", "data" ]

        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        let(:business_id) { business.id }

        let(:payload) do
          {
            bookable_service: {
              name: "Consultation",
              duration_minutes: 30,
              price: 20
            }
          }
        end

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end

      response "403", "forbidden" do
        let(:business_id) { another_business.id }

        let(:payload) do
          {
            bookable_service: {
              name: "Unauthorized Service",
              duration_minutes: 30,
              price: 20
            }
          }
        end

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end

      response "404", "business not found" do
        let(:business_id) { 999_999 }

        let(:payload) do
          {
            bookable_service: {
              name: "Consultation",
              duration_minutes: 30,
              price: 20
            }
          }
        end

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end

      response "422", "validation error" do
        let(:business_id) { business.id }

        let(:payload) do
          {
            bookable_service: {
              name: "",
              duration_minutes: 0,
              price: -1
            }
          }
        end

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end
    end
  end

  path "/api/v1/bookable_services/{id}" do
    parameter name: :id,
              in: :path,
              type: :integer,
              description: "Bookable Service ID"

    get "Get bookable service details" do
      tags "Bookable Services"
      produces "application/json"

      response "200", "bookable service returned" do
        let!(:bookable_service) do
          BookableService.create!(
            business: business,
            name: "Consultation",
            description: "Software consultation session",
            duration_minutes: 30,
            price: 20,
            is_active: true
          )
        end

        let(:id) { bookable_service.id }

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 data: { "$ref" => "#/components/schemas/BookableService" }
               },
               required: [ "success", "data" ]

        run_test!
      end

      response "404", "bookable service not found" do
        let(:id) { 999_999 }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end
    end

    patch "Update a bookable service" do
      tags "Bookable Services"
      consumes "application/json"
      produces "application/json"
      security [ bearerAuth: [] ]

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          bookable_service: {
            type: :object,
            properties: {
              name: { type: :string, example: "Updated Consultation" },
              description: { type: :string, example: "Updated description" },
              duration_minutes: { type: :integer, example: 45 },
              price: { type: :number, format: :float, example: 30.0 },
              is_active: { type: :boolean, example: true }
            }
          }
        },
        required: [ "bookable_service" ]
      }

      response "200", "bookable service updated" do
        let!(:bookable_service) do
          BookableService.create!(
            business: business,
            name: "Consultation",
            duration_minutes: 30,
            price: 20,
            is_active: true
          )
        end

        let(:id) { bookable_service.id }

        let(:payload) do
          {
            bookable_service: {
              name: "Updated Consultation",
              duration_minutes: 45,
              price: 30
            }
          }
        end

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 message: { type: :string, example: "Bookable service updated successfully" },
                 data: { "$ref" => "#/components/schemas/BookableService" }
               },
               required: [ "success", "message", "data" ]

        run_test!
      end

      response "401", "unauthorized" do
        let!(:bookable_service) do
          BookableService.create!(
            business: business,
            name: "Consultation",
            duration_minutes: 30,
            price: 20,
            is_active: true
          )
        end

        let(:Authorization) { nil }
        let(:id) { bookable_service.id }

        let(:payload) do
          {
            bookable_service: {
              name: "Updated Consultation"
            }
          }
        end

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end

      response "403", "forbidden" do
        let!(:bookable_service) do
          BookableService.create!(
            business: another_business,
            name: "Another Service",
            duration_minutes: 30,
            price: 20,
            is_active: true
          )
        end

        let(:id) { bookable_service.id }

        let(:payload) do
          {
            bookable_service: {
              name: "Hacked Service"
            }
          }
        end

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end

      response "404", "bookable service not found" do
        let(:id) { 999_999 }

        let(:payload) do
          {
            bookable_service: {
              name: "Updated Consultation"
            }
          }
        end

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end

      response "422", "validation error" do
        let!(:bookable_service) do
          BookableService.create!(
            business: business,
            name: "Consultation",
            duration_minutes: 30,
            price: 20,
            is_active: true
          )
        end

        let(:id) { bookable_service.id }

        let(:payload) do
          {
            bookable_service: {
              name: "",
              duration_minutes: 0,
              price: -1
            }
          }
        end

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end
    end

    delete "Delete a bookable service" do
      tags "Bookable Services"
      produces "application/json"
      security [ bearerAuth: [] ]

      response "200", "bookable service deleted" do
        let!(:bookable_service) do
          BookableService.create!(
            business: business,
            name: "Consultation",
            duration_minutes: 30,
            price: 20,
            is_active: true
          )
        end

        let(:id) { bookable_service.id }

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 message: { type: :string, example: "Bookable service deleted successfully" }
               },
               required: [ "success", "message" ]

        run_test!
      end

      response "401", "unauthorized" do
        let!(:bookable_service) do
          BookableService.create!(
            business: business,
            name: "Consultation",
            duration_minutes: 30,
            price: 20,
            is_active: true
          )
        end

        let(:Authorization) { nil }
        let(:id) { bookable_service.id }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end

      response "403", "forbidden" do
        let!(:bookable_service) do
          BookableService.create!(
            business: another_business,
            name: "Another Service",
            duration_minutes: 30,
            price: 20,
            is_active: true
          )
        end

        let(:id) { bookable_service.id }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end

      response "404", "bookable service not found" do
        let(:id) { 999_999 }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end
    end
  end
end
