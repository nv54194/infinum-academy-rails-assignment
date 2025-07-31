module Statistics
  class FlightsQuery
    def initialize(relation:)
      @relation = relation
    end

    def with_stats
      @relation
        .left_joins(:bookings)
        .select(
          'flights.id AS flight_id',
          'COALESCE(SUM(bookings.no_of_seats * bookings.seat_price), 0) AS revenue',
          'COALESCE(SUM(bookings.no_of_seats), 0) AS no_of_booked_seats',
          'CAST(COALESCE(SUM(bookings.no_of_seats), 0) AS FLOAT) / flights.no_of_seats AS occupancy'
        )
        .group('flights.id')
    end
  end
end
