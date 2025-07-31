module Api
  module Statistics
    class FlightsController < ApplicationController
      before_action :authorize_admin!

      def index
        flights = Statistics::FlightsQuery.new(relation: Flight.all).with_stats
        render json: Statistics::FlightSerializer.render(flights, root: :flights)
      end

      private

      def authorize_admin!
        head :forbidden unless current_user&.admin?
      end
    end
  end
end
