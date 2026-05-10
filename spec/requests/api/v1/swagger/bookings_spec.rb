require "swagger_helper"

RSpec.describe "Bookings API", type: :request do
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

  before do
    WorkingHour.create!(
      business: business,
      day_of_week: next_sunday.strftime("%A").downcase,
      start_time: "09:00",
      end_time: "17:00",
      is_closed: false
    )

    WorkingHour.create!(
      business: another_business,
      day_of_week: next_sunday.strftime("%A").downcase,
      start_time: "09:00",
      end_time: "17:00",
      is_closed: false
    )
  end

  path "/api/v1/businesses/{business_id}/bookings" do
    parameter name: :business_id, in: :path, type: :integer, description: "Business ID"

    get "List bookings for owned business" do
      tags "Bookings"
      produces "application/json"
      security [ bearerAuth: [] ]

      parameter name: :status,
                in: :query,
                required: false,
                schema: {
                  type: :string,
                  enum: %w[pending confirmed cancelled completed no_show]
                }

      parameter name: :date,
                in: :query,
                required: false,
                schema: { type: :string, format: :date, example: "2026-05-10" }

      parameter name: :bookable_service_id,
                in: :query,
                required: false,
                schema: { type: :integer, example: 1 }

      parameter name: :customer_phone,
                in: :query,
                required: false,
                schema: { type: :string, example: "777777777" }

      parameter name: :upcoming,
                in: :query,
                required: false,
                schema: { type: :boolean, example: true }

      parameter name: :past,
                in: :query,
                required: false,
                schema: { type: :boolean, example: false }

      response "200", "bookings returned" do
        let(:business_id) { business.id }
        let(:status) { nil }
        let(:date) { nil }
        let(:bookable_service_id) { nil }
        let(:customer_phone) { nil }
        let(:upcoming) { nil }
        let(:past) { nil }

        before do
          Booking.create!(
            business: business,
            bookable_service: bookable_service,
            customer_name: "Ahmed Ali",
            customer_phone: "777777777",
            customer_email: "ahmed@example.com",
            start_at: start_at,
            end_at: start_at + 30.minutes,
            status: :confirmed
          )
        end

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 data: {
                   type: :array,
                   items: { "$ref" => "#/components/schemas/Booking" }
                 }
               },
               required: [ "success", "data" ]

        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }
        let(:business_id) { business.id }
        let(:status) { nil }
        let(:date) { nil }
        let(:bookable_service_id) { nil }
        let(:customer_phone) { nil }
        let(:upcoming) { nil }
        let(:past) { nil }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end

      response "403", "forbidden" do
        let(:business_id) { another_business.id }
        let(:status) { nil }
        let(:date) { nil }
        let(:bookable_service_id) { nil }
        let(:customer_phone) { nil }
        let(:upcoming) { nil }
        let(:past) { nil }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end
    end

    post "Create booking" do
      tags "Bookings"
      consumes "application/json"
      produces "application/json"

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          booking: {
            type: :object,
            properties: {
              bookable_service_id: { type: :integer, example: 1 },
              customer_name: { type: :string, example: "Ahmed Ali" },
              customer_phone: { type: :string, example: "777777777" },
              customer_email: { type: :string, example: "ahmed@example.com" },
              start_at: { type: :string, format: "date-time" },
              notes: { type: :string, example: "I need consultation" }
            },
            required: [ "bookable_service_id", "customer_name", "customer_phone", "start_at" ]
          }
        },
        required: [ "booking" ]
      }

      response "201", "booking created" do
        let(:business_id) { business.id }

        let(:payload) do
          {
            booking: {
              bookable_service_id: bookable_service.id,
              customer_name: "Ahmed Ali",
              customer_phone: "777777777",
              customer_email: "ahmed@example.com",
              start_at: start_at.iso8601,
              notes: "I need consultation"
            }
          }
        end

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 message: { type: :string, example: "Booking created successfully" },
                 data: { "$ref" => "#/components/schemas/Booking" }
               },
               required: [ "success", "message", "data" ]

        run_test!
      end

      response "422", "validation or business rule error" do
        let(:business_id) { business.id }

        before do
          Booking.create!(
            business: business,
            bookable_service: bookable_service,
            customer_name: "Existing Customer",
            customer_phone: "711111111",
            start_at: start_at,
            end_at: start_at + 30.minutes,
            status: :confirmed
          )
        end

        let(:payload) do
          {
            booking: {
              bookable_service_id: bookable_service.id,
              customer_name: "Conflict Customer",
              customer_phone: "722222222",
              start_at: start_at.iso8601
            }
          }
        end

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end
    end
  end

  path "/api/v1/bookings/{id}" do
    parameter name: :id, in: :path, type: :integer, description: "Booking ID"

    get "Get booking details" do
      tags "Bookings"
      produces "application/json"
      security [ bearerAuth: [] ]

      response "200", "booking returned" do
        let!(:booking) do
          Booking.create!(
            business: business,
            bookable_service: bookable_service,
            customer_name: "Ahmed Ali",
            customer_phone: "777777777",
            start_at: start_at,
            end_at: start_at + 30.minutes,
            status: :confirmed
          )
        end

        let(:id) { booking.id }

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 data: { "$ref" => "#/components/schemas/Booking" }
               },
               required: [ "success", "data" ]

        run_test!
      end

      response "401", "unauthorized" do
        let!(:booking) do
          Booking.create!(
            business: business,
            bookable_service: bookable_service,
            customer_name: "Ahmed Ali",
            customer_phone: "777777777",
            start_at: start_at,
            end_at: start_at + 30.minutes,
            status: :confirmed
          )
        end

        let(:Authorization) { nil }
        let(:id) { booking.id }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end

      response "403", "forbidden" do
        let!(:booking) do
          Booking.create!(
            business: another_business,
            bookable_service: another_bookable_service,
            customer_name: "Other Customer",
            customer_phone: "711111111",
            start_at: start_at,
            end_at: start_at + 30.minutes,
            status: :confirmed
          )
        end

        let(:id) { booking.id }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end

      response "404", "booking not found" do
        let(:id) { 999_999 }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end
    end
  end

  path "/api/v1/bookings/{id}/confirm" do
    parameter name: :id, in: :path, type: :integer, description: "Booking ID"

    patch "Confirm booking" do
      tags "Bookings"
      produces "application/json"
      security [ bearerAuth: [] ]

      response "200", "booking confirmed" do
        let!(:booking) do
          Booking.create!(
            business: business,
            bookable_service: bookable_service,
            customer_name: "Ahmed Ali",
            customer_phone: "777777777",
            start_at: start_at,
            end_at: start_at + 30.minutes,
            status: :pending
          )
        end

        let(:id) { booking.id }

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 message: { type: :string, example: "Booking confirmed successfully" },
                 data: { "$ref" => "#/components/schemas/Booking" }
               },
               required: [ "success", "message", "data" ]

        run_test!
      end

      response "422", "invalid status transition" do
        let!(:booking) do
          Booking.create!(
            business: business,
            bookable_service: bookable_service,
            customer_name: "Ahmed Ali",
            customer_phone: "777777777",
            start_at: start_at,
            end_at: start_at + 30.minutes,
            status: :cancelled
          )
        end

        let(:id) { booking.id }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end
    end
  end

  path "/api/v1/bookings/{id}/cancel" do
    parameter name: :id, in: :path, type: :integer, description: "Booking ID"

    patch "Cancel booking" do
      tags "Bookings"
      produces "application/json"
      security [ bearerAuth: [] ]

      response "200", "booking cancelled" do
        let!(:booking) do
          Booking.create!(
            business: business,
            bookable_service: bookable_service,
            customer_name: "Ahmed Ali",
            customer_phone: "777777777",
            start_at: start_at,
            end_at: start_at + 30.minutes,
            status: :confirmed
          )
        end

        let(:id) { booking.id }

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 message: { type: :string, example: "Booking cancelled successfully" },
                 data: { "$ref" => "#/components/schemas/Booking" }
               },
               required: [ "success", "message", "data" ]

        run_test!
      end
    end
  end

  path "/api/v1/bookings/{id}/complete" do
    parameter name: :id, in: :path, type: :integer, description: "Booking ID"

    patch "Complete booking" do
      tags "Bookings"
      produces "application/json"
      security [ bearerAuth: [] ]

      response "200", "booking completed" do
        let!(:booking) do
          Booking.create!(
            business: business,
            bookable_service: bookable_service,
            customer_name: "Ahmed Ali",
            customer_phone: "777777777",
            start_at: 1.hour.ago,
            end_at: 30.minutes.ago,
            status: :confirmed
          )
        end

        let(:id) { booking.id }

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 message: { type: :string, example: "Booking completed successfully" },
                 data: { "$ref" => "#/components/schemas/Booking" }
               },
               required: [ "success", "message", "data" ]

        run_test!
      end

      response "422", "booking has not ended yet" do
        let!(:booking) do
          Booking.create!(
            business: business,
            bookable_service: bookable_service,
            customer_name: "Ahmed Ali",
            customer_phone: "777777777",
            start_at: 10.minutes.ago,
            end_at: 20.minutes.from_now,
            status: :confirmed
          )
        end

        let(:id) { booking.id }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end
    end
  end

  path "/api/v1/bookings/{id}/no_show" do
    parameter name: :id, in: :path, type: :integer, description: "Booking ID"

    patch "Mark booking as no-show" do
      tags "Bookings"
      produces "application/json"
      security [ bearerAuth: [] ]

      response "200", "booking marked as no-show" do
        let!(:booking) do
          Booking.create!(
            business: business,
            bookable_service: bookable_service,
            customer_name: "Ahmed Ali",
            customer_phone: "777777777",
            start_at: 30.minutes.ago,
            end_at: 10.minutes.from_now,
            status: :confirmed
          )
        end

        let(:id) { booking.id }

        schema type: :object,
               properties: {
                 success: { type: :boolean, example: true },
                 message: { type: :string, example: "Booking marked as no-show successfully" },
                 data: { "$ref" => "#/components/schemas/Booking" }
               },
               required: [ "success", "message", "data" ]

        run_test!
      end

      response "422", "booking has not started yet" do
        let!(:booking) do
          Booking.create!(
            business: business,
            bookable_service: bookable_service,
            customer_name: "Ahmed Ali",
            customer_phone: "777777777",
            start_at: 1.hour.from_now,
            end_at: 90.minutes.from_now,
            status: :confirmed
          )
        end

        let(:id) { booking.id }

        schema "$ref" => "#/components/schemas/ErrorResponse"

        run_test!
      end
    end
  end
end
