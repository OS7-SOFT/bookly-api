require "rails_helper"

RSpec.describe JsonWebToken do
  describe ".encode" do
    it "returns a JWT token string" do
      token = described_class.encode({ user_id: 1 })

      expect(token).to be_a(String)
      expect(token.split(".").size).to eq(3)
    end

    it "includes the payload data when decoded" do
      token = described_class.encode({ user_id: 1 })

      decoded_payload = described_class.decode(token)

      expect(decoded_payload[:user_id]).to eq(1)
      expect(decoded_payload[:exp]).to be_present
    end
  end

  describe ".decode" do
    it "decodes a valid token" do
      token = described_class.encode({ user_id: 10 })

      decoded_payload = described_class.decode(token)

      expect(decoded_payload).to be_present
      expect(decoded_payload[:user_id]).to eq(10)
    end

    it "returns nil for invalid token" do
      decoded_payload = described_class.decode("invalid.token.value")

      expect(decoded_payload).to be_nil
    end

    it "returns nil for expired token" do
      token = described_class.encode(
        { user_id: 1 },
        exp: 1.minute.ago
      )

      decoded_payload = described_class.decode(token)

      expect(decoded_payload).to be_nil
    end
  end
end
