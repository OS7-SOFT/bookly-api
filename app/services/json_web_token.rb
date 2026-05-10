class JsonWebToken
  ALGORITHM = "HS256"
  DEFAULT_EXPIRATION = 24.hours

  class << self
    def encode(payload, exp: DEFAULT_EXPIRATION.from_now)
      payload = payload.dup
      payload[:exp] = exp.to_i

      JWT.encode(payload, secret_key, ALGORITHM)
    end

    def decode(token)
      decoded = JWT.decode(
        token,
        secret_key,
        true,
        { algorithm: ALGORITHM }
      )

      decoded.first.with_indifferent_access
    rescue JWT::ExpiredSignature
      nil
    rescue JWT::DecodeError
      nil
    end

    private

    def secret_key
      Rails.application.credentials.secret_key_base
    end
  end
end
