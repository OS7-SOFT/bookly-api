require "swagger_helper"

RSpec.describe "Working Hours API", type: :request do
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
    Business.create!(user: user, name: "Bookly Center", is_active: true)
  end

  let!(:another_business) do
    Business.create!(user: another_user, name: "Another Business", is_active: true)
  end

  path "/api/v1/businesses/{business_id}/working_hours" do
    parameter name: :business_id, in: :path, type: :integer, description: "Business ID"

    get "List working hours for a business" do
      tags "Working Hours"
      produces "application/json"

      response "200", "working hours returned" do
        let(:business_id) { business.id }

        before do
          WorkingHour.create!(
            business: business,
            day_of_week: :sunday,
            start_time: "09:00",
            end_time: "17:00",
            is_closed: false
          )
        end

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 data: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/WorkingHour" }
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

    post "Create working hour" do
      tags "Working Hours"
      consumes "application/json"
      produces "application/json"
      security [ bearerAuth: [] ]

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          working_hour: {
            type: :object,
            properties: {
              day_of_week: {
                type: :string,
                enum: %w[sunday monday tuesday wednesday thursday friday saturday],
                example: "sunday"
              },
              start_time: { type: :string, example: "09:00" },
              end_time: { type: :string, example: "17:00" },
              is_closed: { type: :boolean, example: false }
            },
            required: [ "day_of_week" ]
          }
        },
        required: [ "working_hour" ]
      }

      response "201", "working hour created" do
        let(:business_id) { business.id }

        let(:payload) do
          {
            working_hour: {
              day_of_week: "sunday",
              start_time: "09:00",
              end_time: "17:00",
              is_closed: false
            }
          }
        end

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 message: { type: :string, example: "Working hour created successfully" },
                 data: { "$ref" => "#/components/schemas/WorkingHour" }
               },
               required: [ "success", "message", "data" ]

        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        let(:business_id) { business.id }

        let(:payload) do
          {
            working_hour: {
              day_of_week: "monday",
              start_time: "09:00",
              end_time: "17:00",
              is_closed: false
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
            working_hour: {
              day_of_week: "monday",
              start_time: "09:00",
              end_time: "17:00",
              is_closed: false
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
            working_hour: {
              day_of_week: "sunday",
              start_time: "18:00",
              end_time: "09:00",
              is_closed: false
            }
          }
        end

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end
    end
  end

  path "/api/v1/working_hours/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "Working Hour ID"

    get "Get working hour details" do
      tags "Working Hours"
      produces "application/json"

      response "200", "working hour returned" do
        let!(:working_hour) do
          WorkingHour.create!(
            business: business,
            day_of_week: :sunday,
            start_time: "09:00",
            end_time: "17:00",
            is_closed: false
          )
        end

        let(:id) { working_hour.id }

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 data: { "$ref" => "#/components/schemas/WorkingHour" }
               },
               required: [ "success", "data" ]

        run_test!
      end

      response "404", "working hour not found" do
        let(:id) { 999_999 }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end
    end

    patch "Update working hour" do
      tags "Working Hours"
      consumes "application/json"
      produces "application/json"
      security [ bearerAuth: [] ]

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          working_hour: {
            type: :object,
            properties: {
              day_of_week: {
                type: :string,
                enum: %w[sunday monday tuesday wednesday thursday friday saturday],
                example: "sunday"
              },
              start_time: { type: :string, example: "08:00" },
              end_time: { type: :string, example: "16:00" },
              is_closed: { type: :boolean, example: false }
            }
          }
        },
        required: [ "working_hour" ]
      }

      response "200", "working hour updated" do
        let!(:working_hour) do
          WorkingHour.create!(
            business: business,
            day_of_week: :sunday,
            start_time: "09:00",
            end_time: "17:00",
            is_closed: false
          )
        end

        let(:id) { working_hour.id }

        let(:payload) do
          {
            working_hour: {
              start_time: "08:00",
              end_time: "16:00"
            }
          }
        end

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 message: { type: :string, example: "Working hour updated successfully" },
                 data: { "$ref" => "#/components/schemas/WorkingHour" }
               },
               required: [ "success", "message", "data" ]

        run_test!
      end

      response "401", "unauthorized" do
        let!(:working_hour) do
          WorkingHour.create!(
            business: business,
            day_of_week: :sunday,
            start_time: "09:00",
            end_time: "17:00",
            is_closed: false
          )
        end

        let(:Authorization) { nil }
        let(:id) { working_hour.id }

        let(:payload) do
          {
            working_hour: {
              start_time: "08:00",
              end_time: "16:00"
            }
          }
        end

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end

      response "403", "forbidden" do
        let!(:working_hour) do
          WorkingHour.create!(
            business: another_business,
            day_of_week: :sunday,
            start_time: "09:00",
            end_time: "17:00",
            is_closed: false
          )
        end

        let(:id) { working_hour.id }

        let(:payload) do
          {
            working_hour: {
              start_time: "08:00",
              end_time: "16:00"
            }
          }
        end

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end

      response "404", "working hour not found" do
        let(:id) { 999_999 }

        let(:payload) do
          {
            working_hour: {
              start_time: "08:00",
              end_time: "16:00"
            }
          }
        end

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end

      response "422", "validation error" do
        let!(:working_hour) do
          WorkingHour.create!(
            business: business,
            day_of_week: :sunday,
            start_time: "09:00",
            end_time: "17:00",
            is_closed: false
          )
        end

        let(:id) { working_hour.id }

        let(:payload) do
          {
            working_hour: {
              start_time: "18:00",
              end_time: "09:00"
            }
          }
        end

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end
    end

    delete "Delete working hour" do
      tags "Working Hours"
      produces "application/json"
      security [ bearerAuth: [] ]

      response "200", "working hour deleted" do
        let!(:working_hour) do
          WorkingHour.create!(
            business: business,
            day_of_week: :sunday,
            start_time: "09:00",
            end_time: "17:00",
            is_closed: false
          )
        end

        let(:id) { working_hour.id }

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 message: { type: :string, example: "Working hour deleted successfully" }
               },
               required: [ "success", "message" ]

        run_test!
      end

      response "401", "unauthorized" do
        let!(:working_hour) do
          WorkingHour.create!(
            business: business,
            day_of_week: :sunday,
            start_time: "09:00",
            end_time: "17:00",
            is_closed: false
          )
        end

        let(:Authorization) { nil }
        let(:id) { working_hour.id }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end

      response "403", "forbidden" do
        let!(:working_hour) do
          WorkingHour.create!(
            business: another_business,
            day_of_week: :sunday,
            start_time: "09:00",
            end_time: "17:00",
            is_closed: false
          )
        end

        let(:id) { working_hour.id }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end

      response "404", "working hour not found" do
        let(:id) { 999_999 }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end
    end
  end
end
