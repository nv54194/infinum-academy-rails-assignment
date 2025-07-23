module Api
  class FlightsController < ApplicationController
    before_action :set_flight, only: [:show, :update, :destroy]

    def index
      flights = Flight.all
      render json: FlightSerializer.render(flights, root: :flights), status: :ok
    end

    def show
      render json: FlightSerializer.render(@flight, root: :flight), status: :ok
    end

    def create
      flight = Flight.new(flight_params)
      if flight.save
        render json: FlightSerializer.render(flight, root: :flight), status: :created
      else
        render_bad_request(flight.errors.full_messages)
      end
    end

    def update
      if @flight.update(flight_params)
        render json: FlightSerializer.render(@flight, root: :flight), status: :ok
      else
        render_bad_request(@flight.errors.full_messages)
      end
    end

    def destroy
      @flight.destroy
      head :no_content
    end

    private

    def set_flight
      @flight = Flight.find_by(id: params[:id])
      render_not_found unless @flight
    end

    def flight_params
      params.require(:flight).permit(:name,
                                     :no_of_seats,
                                     :base_price,
                                     :departs_at,
                                     :arrives_at)
    end
  end
end
