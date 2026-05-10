class ApplicationController < ActionController::API
  include Authenticatable
  include Authorizable

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  rescue_from ActiveRecord::RecordNotDestroyed, with: :render_record_not_destroyed
  rescue_from ActiveRecord::InvalidForeignKey, with: :render_invalid_foreign_key

  private

  def render_success(data: nil, message: nil, status: :ok)
    response = {
      success: true
    }

    response[:message] = message if message.present?
    response[:data] = data unless data.nil?

    render json: response, status: status
  end

  def render_error(message:, errors: [], status: :unprocessable_content)
    render json: {
      success: false,
      message: message,
      errors: Array(errors)
    }, status: status
  end

  def render_not_found(exception)
    render_error(
      message: "Resource not found",
      errors: [ exception.message ],
      status: :not_found
    )
  end

  def render_bad_request(exception)
    render_error(
      message: "Bad request",
      errors: [ exception.message ],
      status: :bad_request
    )
  end

  def render_record_invalid(exception)
    render_error(
      message: "Validation failed",
      errors: exception.record.errors.full_messages,
      status: :unprocessable_content
    )
  end

  def render_record_not_destroyed(exception)
    render_error(
      message: "Resource could not be deleted",
      errors: exception.record&.errors&.full_messages.presence || [ exception.message ],
      status: :unprocessable_content
    )
  end

  def render_invalid_foreign_key(exception)
    render_error(
      message: "Resource could not be deleted because it is linked to other records",
      errors: [ exception.message ],
      status: :unprocessable_content
    )
  end
end
