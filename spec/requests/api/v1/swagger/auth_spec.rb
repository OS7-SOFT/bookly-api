require "swagger_helper"

RSpec.describe "Auth API", type: :request do
  path "/api/v1/auth/register" do
    post "Register a new user" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              full_name: { type: :string, example: "Osama Yeslam" },
              email: { type: :string, example: "osama@example.com" },
              password: { type: :string, example: "password123" },
              password_confirmation: { type: :string, example: "password123" }
            },
            required: [ "full_name", "email", "password", "password_confirmation" ]
          }
        },
        required: [ "user" ]
      }

      response "201", "account created" do
        let(:payload) do
          {
            user: {
              full_name: "Osama Yeslam",
              email: "osama@example.com",
              password: "password123",
              password_confirmation: "password123"
            }
          }
        end

        run_test!
      end

      response "422", "validation error" do
        let(:payload) do
          {
            user: {
              full_name: "",
              email: "",
              password: "",
              password_confirmation: ""
            }
          }
        end

        run_test!
      end
    end
  end

  path "/api/v1/auth/login" do
    post "Login user" do
      tags "Auth"
      consumes "application/json"
      produces "application/json"

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              email: { type: :string, example: "osama@example.com" },
              password: { type: :string, example: "password123" }
            },
            required: [ "email", "password" ]
          }
        },
        required: [ "user" ]
      }

      response "200", "logged in successfully" do
        let!(:user) do
          User.create!(
            full_name: "Osama Yeslam",
            email: "osama@example.com",
            password: "password123"
          )
        end

        let(:payload) do
          {
            user: {
              email: "osama@example.com",
              password: "password123"
            }
          }
        end

        run_test!
      end

      response "401", "invalid credentials" do
        let(:payload) do
          {
            user: {
              email: "wrong@example.com",
              password: "wrong-password"
            }
          }
        end

        run_test!
      end
    end
  end

  path "/api/v1/auth/me" do
    get "Get current authenticated user" do
      tags "Auth"
      produces "application/json"
      security [ bearerAuth: [] ]

      response "200", "current user returned" do
        let!(:user) do
          User.create!(
            full_name: "Osama Yeslam",
            email: "osama@example.com",
            password: "password123"
          )
        end

        let(:Authorization) do
          "Bearer #{JsonWebToken.encode({ user_id: user.id })}"
        end

        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { nil }

        run_test!
      end
    end
  end
end
