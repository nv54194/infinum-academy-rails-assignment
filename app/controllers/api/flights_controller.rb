module Api
  class FlightsController < ApplicationController
    before_action :set_flight, only: [:show, :update, :destroy]

    def index
      # render json: FlightSerializer.render(Flight.all, root: :flights), status: :ok
      render json: serialize(Flight.all, root: :flights)
    end

    def show
      # render json: FlightSerializer.render(flight, root: :flight), status: :ok
      render json: serialize(flight, root: :flight)
    end

    def create
      new_flight = Flight.new(flight_params)
      if new_flight.save
        render json: FlightSerializer.render(new_flight, root: :flight), status: :created
      else
        render_bad_request(new_flight.errors.messages)
      end
    end

    def update
      if flight.update(flight_params)
        render json: FlightSerializer.render(flight, root: :flight), status: :ok
      else
        render_bad_request(flight.errors.messages)
      end
    end

    def destroy
      flight.destroy
      head :no_content
    end

    private

    def set_flight
      render_not_found unless flight
    end

    def flight
      @flight ||= Flight.find_by(id: params[:id])
    end

    def flight_params
      params.require(:flight).permit(:name, :no_of_seats, :base_price, :departs_at, :arrives_at,
                                     :company_id)
    end
  end
end
