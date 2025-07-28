module Api
  class FlightsController < ApplicationController
    before_action :set_flight, only: [:show, :update, :destroy]
    skip_before_action :authenticate_user, only: [:index, :show]

    def index
      render json: serialize(Flight.all, root: :flights)
    end

    def show
      render json: serialize(flight, root: :flight)
    end

    def create
      authorize Flight
      new_flight = Flight.new(flight_params)
      if new_flight.save
        render json: FlightSerializer.render(new_flight, root: :flight), status: :created
      else
        render_bad_request(new_flight.errors.messages)
      end
    end

    def update
      authorize flight
      if flight.update(flight_params)
        render json: FlightSerializer.render(flight, root: :flight), status: :ok
      else
        render_bad_request(flight.errors.messages)
      end
    end

    def destroy
      authorize flight
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
      params.require(:flight).permit(:name,
                                     :no_of_seats,
                                     :base_price,
                                     :departs_at,
                                     :arrives_at,
                                     :company_id)
    end
  end
end
