class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token

  private

  def current_user
    token = request.headers['Authorization']
    User.find_by(token: token)
  end

  def render_not_found
    render json: { error: 'Not found' }, status: :not_found
  end

  def render_bad_request(errors)
    render json: { errors: errors }, status: :bad_request
  end

  def serialize(resource, root:)
    serializer = request.headers['X_API_SERIALIZER']
    data = serialized_data(resource, serializer)

    if serializer == 'jsonapi'
      data
    else
      (request.headers['X_API_SERIALIZER_ROOT'] == '0' ? data : { root => data })
    end
  end

  def serialized_data(resource, serializer)
    if serializer == 'jsonapi'
      serializer_class = "JsonapiSerializer::#{resource.model_name}Serializer".constantize
      serializer_class.new(resource).serializable_hash
    else
      serializer_class = "#{resource.model_name}Serializer".constantize
      serializer_class.render_as_hash(resource)
    end
  end
end
