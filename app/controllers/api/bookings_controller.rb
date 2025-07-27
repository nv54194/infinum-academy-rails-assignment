module Api
  class BookingsController < ApplicationController
    before_action :set_booking, only: [:show, :update, :destroy]

    def index
      bookings = policy_scope(Booking)
      render json: serialize(bookings, root: :bookings)
    end

    def show
      authorize booking
      render json: serialize(booking, root: :booking)
    end

    def create
      new_booking = current_user.bookings.build(booking_params)
      authorize new_booking
      if new_booking.save
        render json: BookingSerializer.render(new_booking, root: :booking), status: :created
      else
        render_bad_request(new_booking.errors.messages)
      end
    end

    def update
      authorize booking
      if booking.update(booking_params)
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
      @booking = Booking.find_by(id: params[:id])
      render_not_found unless @booking
    end

    attr_reader :booking

    def booking_params
      if current_user.admin?
        params.require(:booking).permit(:no_of_seats, :seat_price, :flight_id, :user_id)
      else
        params.require(:booking).permit(:no_of_seats, :seat_price, :flight_id)
      end
    end
  end
end
