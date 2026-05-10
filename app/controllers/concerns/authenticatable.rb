module Authenticatable
  extend ActiveSupport::Concern

  private

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = nil

    token = bearer_token
    return nil if token.blank?

    payload = JsonWebToken.decode(token)
    return nil if payload.blank?

    @current_user = User.find_by(id: payload[:user_id])
  end

  def authenticate_user!
    return if current_user.present?

    render_error(
      message: "Unauthorized",
      errors: [ "You need to sign in before continuing" ],
      status: :unauthorized
    )
  end

  def bearer_token
    authorization_header = request.headers["Authorization"].to_s

    return nil unless authorization_header.start_with?("Bearer ")

    authorization_header.split(" ", 2).last
  end
end
