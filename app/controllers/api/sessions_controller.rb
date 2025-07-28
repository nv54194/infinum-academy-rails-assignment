module Api
  class SessionsController < ApplicationController
    skip_before_action :authenticate_user, only: [:create]
    def create
      user = User.find_by(email: session_params[:email])
      if user&.authenticate(session_params[:password])
        user.regenerate_token
        render json: SessionSerializer.render({ token: user.token, user: user }, root: :session),
               status: :created
      else
        render_bad_request(credentials: ['are invalid'])
      end
    end

    def destroy
      current_user.regenerate_token
      head :no_content
    end

    private

    def session_params
      params.require(:session).permit(:email, :password)
    end
  end
end
