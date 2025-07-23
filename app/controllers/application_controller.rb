class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def render_not_found
    render json: { error: 'Not found' }, status: :not_found
  end

  def render_bad_request(errors)
    render json: { errors: errors }, status: :bad_request
  end
end
