module Api
  class BookingsController < ApplicationController
    before_action :set_booking, only: [:show, :update, :destroy]

    def index
      render json: BookingSerializer.render(Booking.all, root: :bookings), status: :ok
    end

    def show
      render json: BookingSerializer.render(@booking, root: :booking), status: :ok
    end

    def create
      booking = Booking.new(booking_params)
      if booking.save
        render json: BookingSerializer.render(booking, root: :booking), status: :created
      else
        render_bad_request(booking.errors.full_messages)
      end
    end

    def update
      if @booking.update(booking_params)
        render json: BookingSerializer.render(@booking, root: :booking), status: :ok
      else
        render_bad_request(@booking.errors.full_messages)
      end
    end

    def destroy
      @booking.destroy
      head :no_content
    end

    private

    def set_booking
      @booking = Booking.find_by(id: params[:id])
      render_not_found unless @booking
    end

    def booking_params
      params.require(:booking).permit(:no_of_seats, :seat_price, :user_id, :flight_id)
    end
  end
end
