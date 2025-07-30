class BookingPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if user&.admin?
        scope.all
      else
        scope.where(user_id: user.id)
      end
    end
  end

  def show?
    user&.admin? || record.user_id == user.id
  end

  def update?
    user&.admin? || record.user_id == user.id
  end

  def destroy?
    user&.admin? || record.user_id == user.id
  end

  def create?
    user.present?
  end
end
