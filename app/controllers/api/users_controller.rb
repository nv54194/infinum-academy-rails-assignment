module Api
  class UsersController < ApplicationController
    skip_before_action :authenticate_user, only: [:create]
    before_action :set_user, only: [:show, :update, :destroy]

    def index
      authorize User
      users = UsersQuery.new(params: params).result
      render json: serialize(users, root: :users)
    end

    def show
      authorize user
      render json: serialize(user, root: :user)
    end

    def create
      authenticate_user if request.headers['Authorization'].present?
      new_user = User.new(user_params)
      if new_user.save
        render json: UserSerializer.render(new_user, root: :user), status: :created
      else
        render_bad_request(new_user.errors.messages)
      end
    end

    def update
      authorize user
      if user.update(user_params)
        render json: UserSerializer.render(user, root: :user), status: :ok
      else
        render_bad_request(user.errors.messages)
      end
    end

    def destroy
      authorize user
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
      if current_user&.admin?
        params.require(:user).permit(:first_name, :last_name, :email, :password, :role)
      else
        params.require(:user).permit(:first_name, :last_name, :email, :password)
      end
    end
  end
end
