class FlightsQuery
  attr_reader :relation, :params

  def initialize(relation: Flight.all, params: {})
    @relation = relation
    @params = params
  end

  def result
    scope = relation.active
    scope = scope.name_cont(params[:name_cont]) if name_cont?
    scope = scope.departs_at_eq(params[:departs_at_eq]) if departs_at_eq?
    if no_of_available_seats_gteq?
      scope = scope.no_of_available_seats_gteq(params[:no_of_available_seats_gteq])
    end
    scope.order(departs_at: :asc, name: :asc, created_at: :asc)
  end

  private

  def name_cont?
    params[:name_cont].present?
  end

  def departs_at_eq?
    params[:departs_at_eq].present?
  end

  def no_of_available_seats_gteq?
    params[:no_of_available_seats_gteq].present?
  end
end
