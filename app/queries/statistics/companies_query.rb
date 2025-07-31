module Statistics
  class CompaniesQuery
    def initialize(relation:)
      @relation = relation
    end

    def with_stats
      @relation
        .left_joins(flights: :bookings)
        .select(
          'companies.id AS company_id',
          'COALESCE(SUM(bookings.no_of_seats * bookings.seat_price), 0) AS total_revenue',
          'COALESCE(SUM(bookings.no_of_seats), 0) AS total_no_of_booked_seats',
          'AVG(bookings.seat_price) AS average_price_of_seats'
        )
        .group('companies.id')
    end
  end
end
