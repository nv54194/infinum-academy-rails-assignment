module Statistics
  class FlightSerializer < Blueprinter::Base
    field :flight_id
    field :revenue
    field :no_of_booked_seats
    field :occupancy do |flight, _|
      flight[:occupancy].to_f
    end
  end
end
