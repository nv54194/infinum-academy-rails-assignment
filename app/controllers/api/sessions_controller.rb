module Api
  class SessionsController < ApplicationController
    def create
      user = User.find_by(email: session_params[:email])
      if user&.authenticate(session_params[:password])
        user.regenerate_token
        render json: SessionSerializer.render({ token: user.token, user: user }, root: :session),
               status: :created
      else
        render json: { errors: { credentials: ['are invalid'] } }, status: :unauthorized
      end
    end

    def destroy
      if current_user
        current_user.regenerate_token
        head :no_content
      else
        render json: { errors: { token: ['is invalid'] } }, status: :unauthorized
      end
    end

    private

    def session_params
      params.require(:session).permit(:email, :password)
    end
  end
end
