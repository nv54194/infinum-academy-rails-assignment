module Statistics
  class FlightSerializer < Blueprinter::Base
    field :flight_id
    field :revenue
    field :no_of_booked_seats
    field :occupancy
  end
end
