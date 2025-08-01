class UsersQuery
  attr_reader :relation, :params

  def initialize(relation: User.all, params: {})
    @relation = relation
    @params = params
  end

  def result
    scope = relation
    if query?
      q = params[:query]
      scope = scope.email_cont(q)
                   .or(scope.first_name_cont(q))
                   .or(scope.last_name_cont(q))
    end
    scope.order(email: :asc)
  end

  private

  def query?
    params[:query].present?
  end
end
