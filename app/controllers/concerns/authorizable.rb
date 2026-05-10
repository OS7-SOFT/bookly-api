module Authorizable
  extend ActiveSupport::Concern

  private

  def ensure_business_owner!(business)
    return if business.user_id == current_user&.id

    render_error(
      message: "Forbidden",
      errors: [ "You are not allowed to access this resource" ],
      status: :forbidden
    )
  end

  def owns_business?(business)
    business.user_id == current_user&.id
  end
end
