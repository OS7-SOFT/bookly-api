require "swagger_helper"

RSpec.describe "Businesses API", type: :request do
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

  path "/api/v1/businesses" do
    get "List current user's businesses" do
      tags "Businesses"
      produces "application/json"
      security [ bearerAuth: [] ]

      response "200", "businesses returned" do
        before do
          Business.create!(
            user: user,
            name: "Bookly Center",
            description: "Consulting center",
            phone: "777777777",
            email: "info@example.com",
            address: "Aden - Yemen",
            is_active: true
          )

          Business.create!(
            user: another_user,
            name: "Another Business",
            is_active: true
          )
        end

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 data: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/Business" }
                 }
               },
               required: [ "success", "data" ]

        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end
    end

    post "Create a business" do
      tags "Businesses"
      consumes "application/json"
      produces "application/json"
      security [ bearerAuth: [] ]

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          business: {
            type: :object,
            properties: {
              name: { type: :string, example: "Bookly Center" },
              description: { type: :string, example: "We provide consulting services" },
              phone: { type: :string, example: "777777777" },
              email: { type: :string, example: "info@example.com" },
              address: { type: :string, example: "Aden - Yemen" },
              is_active: { type: :boolean, example: true }
            },
            required: [ "name" ]
          }
        },
        required: [ "business" ]
      }

      response "201", "business created" do
        let(:payload) do
          {
            business: {
              name: "Bookly Center",
              description: "We provide consulting services",
              phone: "777777777",
              email: "info@example.com",
              address: "Aden - Yemen",
              is_active: true
            }
          }
        end

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 message: { type: :string, example: "Business created successfully" },
                 data: { "$ref" => "#/components/schemas/Business" }
               },
               required: [ "success", "message", "data" ]

        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }

        let(:payload) do
          {
            business: {
              name: "Bookly Center"
            }
          }
        end

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end

      response "422", "validation error" do
        let(:payload) do
          {
            business: {
              name: ""
            }
          }
        end

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end
    end
  end

  path "/api/v1/businesses/{id}" do
    parameter name: :id,
              in: :path,
              type: :integer,
              description: "Business ID"

    get "Get business details" do
      tags "Businesses"
      produces "application/json"

      response "200", "business returned" do
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

        let(:id) { business.id }

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 data: { "$ref" => "#/components/schemas/Business" }
               },
               required: [ "success", "data" ]

        run_test!
      end

      response "404", "business not found" do
        let(:id) { 999_999 }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end
    end

    patch "Update a business" do
      tags "Businesses"
      consumes "application/json"
      produces "application/json"
      security [ bearerAuth: [] ]

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          business: {
            type: :object,
            properties: {
              name: { type: :string, example: "Updated Bookly Center" },
              description: { type: :string, example: "Updated description" },
              phone: { type: :string, example: "711111111" },
              email: { type: :string, example: "updated@example.com" },
              address: { type: :string, example: "Aden - Yemen" },
              is_active: { type: :boolean, example: true }
            }
          }
        },
        required: [ "business" ]
      }

      response "200", "business updated" do
        let!(:business) do
          Business.create!(
            user: user,
            name: "Bookly Center",
            is_active: true
          )
        end

        let(:id) { business.id }

        let(:payload) do
          {
            business: {
              name: "Updated Bookly Center"
            }
          }
        end

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 message: { type: :string, example: "Business updated successfully" },
                 data: { "$ref" => "#/components/schemas/Business" }
               },
               required: [ "success", "message", "data" ]

        run_test!
      end

      response "401", "unauthorized" do
        let!(:business) do
          Business.create!(
            user: user,
            name: "Bookly Center",
            is_active: true
          )
        end

        let(:Authorization) { nil }
        let(:id) { business.id }

        let(:payload) do
          {
            business: {
              name: "Updated Bookly Center"
            }
          }
        end

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end

      response "403", "forbidden" do
        let!(:business) do
          Business.create!(
            user: another_user,
            name: "Another Business",
            is_active: true
          )
        end

        let(:id) { business.id }

        let(:payload) do
          {
            business: {
              name: "Hacked Business"
            }
          }
        end

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end

      response "404", "business not found" do
        let(:id) { 999_999 }

        let(:payload) do
          {
            business: {
              name: "Updated Bookly Center"
            }
          }
        end

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end

      response "422", "validation error" do
        let!(:business) do
          Business.create!(
            user: user,
            name: "Bookly Center",
            is_active: true
          )
        end

        let(:id) { business.id }

        let(:payload) do
          {
            business: {
              name: ""
            }
          }
        end

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end
    end
  end
end
