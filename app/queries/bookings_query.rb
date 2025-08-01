class BookingsQuery
  attr_reader :relation, :params

  def initialize(relation: Booking.all, params: {})
    @relation = relation
    @params = params
  end

  def result
    scope = relation.joins(:flight).order(
      flights: { departs_at: :asc, name: :asc },
      created_at: :asc
    )
    scope = with_active_flights(scope) if active_flights?
    scope
  end

  def with_active_flights(scope = self.scope)
    scope.merge(Flight.active)
  end

  private

  def active_flights?
    params[:filter] == 'active'
  end
end
