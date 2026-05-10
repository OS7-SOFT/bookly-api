require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Bookly API",
        version: "v1",
        description: "Backend API for managing service-based bookings and appointments."
      },
      servers: [
        {
          url: "http://localhost:3000",
          description: "Local development server"
        }
      ],
      components: {
        securitySchemes: {
          bearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: :JWT
          }
        },
        schemas: {
          ErrorResponse: {
            type: :object,
            properties: {
              success: { type: :boolean, example: false },
              message: { type: :string, example: "Validation failed" },
              errors: {
                type: :array,
                items: { type: :string },
                example: [ "Name can't be blank" ]
              }
            },
            required: [ "success", "message", "errors" ]
          },
          SuccessResponse: {
            type: :object,
            properties: {
              success: { type: :boolean, example: true },
              message: { type: :string, example: "Operation completed successfully" },
              data: { type: :object }
            },
            required: [ "success" ]
          },
          User: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              full_name: { type: :string, example: "Osama Yeslam" },
              email: { type: :string, example: "osama@example.com" },
              created_at: { type: :string, format: "date-time" },
              updated_at: { type: :string, format: "date-time" }
            },
            required: [ "id", "full_name", "email" ]
          },
          AuthResponse: {
            type: :object,
            properties: {
              success: { type: :boolean, example: true },
              message: { type: :string, example: "Logged in successfully" },
              data: {
                type: :object,
                properties: {
                  user: { "$ref" => "#/components/schemas/User" },
                  token: { type: :string, example: "jwt.token.here" }
                },
                required: [ "user", "token" ]
              }
            },
            required: [ "success", "message", "data" ]
          },
          BookableService: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              business_id: { type: :integer, example: 1 },
              name: { type: :string, example: "Consultation" },
              description: { type: :string, nullable: true, example: "Software consultation session" },
              duration_minutes: { type: :integer, example: 30 },
              price: { type: :string, example: "20.0" },
              is_active: { type: :boolean, example: true },
              created_at: { type: :string, format: "date-time" },
              updated_at: { type: :string, format: "date-time" }
            },
            required: [ "id", "business_id", "name", "duration_minutes", "price", "is_active" ]
          },
          Business: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              user_id: { type: :integer, example: 1 },
              name: { type: :string, example: "Bookly Center" },
              description: { type: :string, nullable: true, example: "We provide consulting services" },
              phone: { type: :string, nullable: true, example: "777777777" },
              email: { type: :string, nullable: true, example: "info@example.com" },
              address: { type: :string, nullable: true, example: "Aden - Yemen" },
              is_active: { type: :boolean, example: true },
              created_at: { type: :string, format: "date-time" },
              updated_at: { type: :string, format: "date-time" }
            },
            required: [ "id", "user_id", "name", "is_active" ]
          },
          WorkingHour: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              business_id: { type: :integer, example: 1 },
              day_of_week: { type: :string, example: "sunday" },
              start_time: { type: :string, nullable: true, example: "09:00" },
              end_time: { type: :string, nullable: true, example: "17:00" },
              is_closed: { type: :boolean, example: false },
              created_at: { type: :string, format: "date-time" },
              updated_at: { type: :string, format: "date-time" }
            },
            required: [ "id", "business_id", "day_of_week", "is_closed" ]
          },
          Booking: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              business_id: { type: :integer, example: 1 },
              bookable_service_id: { type: :integer, example: 1 },
              customer_name: { type: :string, example: "Ahmed Ali" },
              customer_phone: { type: :string, example: "777777777" },
              customer_email: { type: :string, nullable: true, example: "ahmed@example.com" },
              start_at: { type: :string, format: "date-time" },
              end_at: { type: :string, format: "date-time" },
              status: {
                type: :string,
                enum: %w[pending confirmed cancelled completed no_show],
                example: "pending"
              },
              notes: { type: :string, nullable: true, example: "I need consultation" },
              created_at: { type: :string, format: "date-time" },
              updated_at: { type: :string, format: "date-time" }
            },
            required: [
              "id",
              "business_id",
              "bookable_service_id",
              "customer_name",
              "customer_phone",
              "start_at",
              "end_at",
              "status"
            ]
          },
          Availability: {
            type: :object,
            properties: {
              date: { type: :string, format: :date, example: "2026-05-10" },
              business_id: { type: :integer, example: 1 },
              bookable_service_id: { type: :integer, example: 1 },
              duration_minutes: { type: :integer, example: 30 },
              slot_interval_minutes: { type: :integer, example: 30 },
              available_slots: {
                type: :array,
                items: { type: :string, example: "09:00" },
                example: [ "09:00", "09:30", "10:00" ]
              }
            },
            required: [
              "date",
              "business_id",
              "bookable_service_id",
              "duration_minutes",
              "slot_interval_minutes",
              "available_slots"
            ]
          }
        }
      }
    }
  }

  config.openapi_format = :yaml
end
