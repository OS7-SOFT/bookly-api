require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  describe "POST /api/v1/auth/register" do
    let(:valid_params) do
      {
        user: {
          full_name: "Osama Yeslam",
          email: "osama@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    it "registers a new user successfully" do
      expect {
        post "/api/v1/auth/register", params: valid_params
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(true)
      expect(json["message"]).to eq("Account created successfully")
      expect(json["data"]["user"]["full_name"]).to eq("Osama Yeslam")
      expect(json["data"]["user"]["email"]).to eq("osama@example.com")
      expect(json["data"]["user"]).not_to have_key("password_digest")
      expect(json["data"]["token"]).to be_present
    end

    it "normalizes email before saving" do
      post "/api/v1/auth/register", params: {
        user: {
          full_name: "Osama Yeslam",
          email: "  OSAMA@EXAMPLE.COM  ",
          password: "password123",
          password_confirmation: "password123"
        }
      }

      expect(response).to have_http_status(:created)

      user = User.last

      expect(user.email).to eq("osama@example.com")
    end

    it "returns validation errors when required fields are missing" do
      post "/api/v1/auth/register", params: {
        user: {
          full_name: "",
          email: "",
          password: "",
          password_confirmation: ""
        }
      }

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Account could not be created")
      expect(json["errors"]).to include("Full name can't be blank")
      expect(json["errors"]).to include("Email can't be blank")
    end

    it "returns validation error when email already exists" do
      User.create!(
        full_name: "Existing User",
        email: "osama@example.com",
        password: "password123"
      )

      expect {
        post "/api/v1/auth/register", params: valid_params
      }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["errors"]).to include("Email has already been taken")
    end

    it "returns validation error when password confirmation does not match" do
      post "/api/v1/auth/register", params: {
        user: {
          full_name: "Osama Yeslam",
          email: "osama@example.com",
          password: "password123",
          password_confirmation: "wrong-password"
        }
      }

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["errors"]).to include("Password confirmation doesn't match Password")
    end

    it "returns bad request when user param is missing" do
      post "/api/v1/auth/register", params: {}

      expect(response).to have_http_status(:bad_request)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Bad request")
      expect(json["errors"]).to be_present
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) do
      User.create!(
        full_name: "Osama Yeslam",
        email: "osama@example.com",
        password: "password123"
      )
    end

    it "logs in successfully with valid credentials" do
      post "/api/v1/auth/login", params: {
        user: {
          email: "osama@example.com",
          password: "password123"
        }
      }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(true)
      expect(json["message"]).to eq("Logged in successfully")
      expect(json["data"]["user"]["id"]).to eq(user.id)
      expect(json["data"]["user"]["email"]).to eq("osama@example.com")
      expect(json["data"]["user"]).not_to have_key("password_digest")
      expect(json["data"]["token"]).to be_present
    end

    it "logs in successfully with email in different case and spaces" do
      post "/api/v1/auth/login", params: {
        user: {
          email: "  OSAMA@EXAMPLE.COM  ",
          password: "password123"
        }
      }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(true)
      expect(json["data"]["user"]["id"]).to eq(user.id)
      expect(json["data"]["token"]).to be_present
    end

    it "returns unauthorized with wrong password" do
      post "/api/v1/auth/login", params: {
        user: {
          email: "osama@example.com",
          password: "wrong-password"
        }
      }

      expect(response).to have_http_status(:unauthorized)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Invalid email or password")
      expect(json["errors"]).to include("Invalid email or password")
    end

    it "returns unauthorized when email does not exist" do
      post "/api/v1/auth/login", params: {
        user: {
          email: "notfound@example.com",
          password: "password123"
        }
      }

      expect(response).to have_http_status(:unauthorized)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Invalid email or password")
      expect(json["errors"]).to include("Invalid email or password")
    end

    it "returns bad request when user param is missing" do
      post "/api/v1/auth/login", params: {}

      expect(response).to have_http_status(:bad_request)

      json = JSON.parse(response.body)

      expect(json["success"]).to eq(false)
      expect(json["message"]).to eq("Bad request")
      expect(json["errors"]).to be_present
    end
  end

  describe "GET /api/v1/auth/me" do
  let!(:user) do
    User.create!(
      full_name: "Osama Yeslam",
      email: "osama@example.com",
      password: "password123"
    )
  end

  let(:token) { JsonWebToken.encode({ user_id: user.id }) }

  it "returns current user with valid token" do
    get "/api/v1/auth/me", headers: {
      "Authorization" => "Bearer #{token}"
    }

    expect(response).to have_http_status(:ok)

    json = JSON.parse(response.body)

    expect(json["success"]).to eq(true)
    expect(json["data"]["user"]["id"]).to eq(user.id)
    expect(json["data"]["user"]["email"]).to eq("osama@example.com")
    expect(json["data"]["user"]).not_to have_key("password_digest")
  end

  it "returns unauthorized without token" do
    get "/api/v1/auth/me"

    expect(response).to have_http_status(:unauthorized)

    json = JSON.parse(response.body)

    expect(json["success"]).to eq(false)
    expect(json["message"]).to eq("Unauthorized")
  end

  it "returns unauthorized with invalid token" do
    get "/api/v1/auth/me", headers: {
      "Authorization" => "Bearer invalid-token"
    }

    expect(response).to have_http_status(:unauthorized)

    json = JSON.parse(response.body)

    expect(json["success"]).to eq(false)
    expect(json["message"]).to eq("Unauthorized")
  end
end
end
