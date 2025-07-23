module Api
  class UsersController < ApplicationController
    before_action :set_user, only: [:show, :update, :destroy]

    def index
      render json: UserSerializer.render(User.all, root: :users), status: :ok
    end

    def show
      render json: UserSerializer.render(user, root: :user), status: :ok
    end

    def create
      new_user = User.new(user_params)
      if new_user.save
        render json: UserSerializer.render(new_user, root: :user), status: :created
      else
        render_bad_request(new_user.errors.full_messages)
      end
    end

    def update
      if user.update(user_params)
        render json: UserSerializer.render(user, root: :user), status: :ok
      else
        render_bad_request(user.errors.full_messages)
      end
    end

    def destroy
      user.destroy
      head :no_content
    end

    private

    def set_user
      render_not_found unless user
    end

    def user
      @user ||= User.find_by(id: params[:id])
    end

    def user_params
      params.require(:user).permit(:first_name, :last_name, :email)
    end
  end
end
