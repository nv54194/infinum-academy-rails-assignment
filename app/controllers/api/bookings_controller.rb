module Api
  class BookingsController < ApplicationController
    before_action :set_booking, only: [:show, :update, :destroy]

    def index
      # render json: BookingSerializer.render(Booking.all, root: :bookings), status: :ok
      render json: serialize(Booking.all, root: :bookings)
    end

    def show
      # render json: BookingSerializer.render(booking, root: :booking), status: :ok
      render json: serialize(booking, root: :booking)
    end

    def create
      new_booking = Booking.new(booking_params)
      if new_booking.save
        render json: BookingSerializer.render(new_booking, root: :booking), status: :created
      else
        render_bad_request(new_booking.errors.messages)
      end
    end

    def update
      if booking.update(booking_params)
        render json: BookingSerializer.render(booking, root: :booking), status: :ok
      else
        render_bad_request(booking.errors.messages)
      end
    end

    def destroy
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

    def booking_params
      params.require(:booking).permit(:no_of_seats, :seat_price, :user_id, :flight_id)
    end
  end
end
