module Api
  module Statistics
    class FlightsController < ApplicationController
      def index
        authorize [:statistics, :flight]
        flights = ::Statistics::FlightsQuery.new(relation: Flight.all).with_stats
        render json: ::Statistics::FlightSerializer.render(flights, root: :flights)
      end
    end
  end
end
