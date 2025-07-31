module Api
  class BookingsController < ApplicationController
    before_action :set_booking, only: [:show, :update, :destroy]

    def index
      bookings = BookingsQuery.new(relation: policy_scope(Booking), params: params).result
      render json: serialize(bookings, root: :bookings)
    end

    def show
      authorize booking
      render json: serialize(booking, root: :booking)
    end

    def create
      new_booking = build_booking
      authorize new_booking
      if new_booking.save
        render json: BookingSerializer.render(new_booking, root: :booking), status: :created
      else
        render_bad_request(new_booking.errors.messages)
      end
    end

    def update
      authorize booking
      permitted_params = booking_params
      permitted_params = permitted_params.except(:user_id) unless current_user.admin?
      if booking.update(permitted_params)
        render json: BookingSerializer.render(booking, root: :booking), status: :ok
      else
        render_bad_request(booking.errors.messages)
      end
    end

    def destroy
      authorize booking
      booking.destroy
      head :no_content
    end

    private

    def set_booking
      render_not_found unless booking
    end

    def booking
      @booking ||= Booking.find_by(id: params[:id])
    end

    def build_booking
      if current_user.admin? && booking_params[:user_id]
        user = User.find(booking_params[:user_id])
        user.bookings.build(booking_params.except(:user_id))
      else
        current_user.bookings.build(booking_params)
      end
    end

    def booking_params
      params.require(:booking).permit(:no_of_seats, :seat_price, :user_id, :flight_id)
    end
  end
end
