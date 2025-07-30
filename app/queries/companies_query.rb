class Companiesscope
  attr_reader :relation, :params

  def initialize(relation: Company.all, params: {})
    @relation = relation
    @params = params
  end

  def result
    scope = relation.order(name: :asc)
    scope = with_active_flights(scope) if active_flights?
    scope
  end

  def with_active_flights(scope = relation)
    scope.joins(:flights)
         .where(flights: { departs_at: Time.current.. })
         .distinct
  end

  private

  def active_flights?
    params[:filter] == 'active'
  end
end
