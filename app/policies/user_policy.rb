class UserPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    user&.admin?
  end

  def show?
    user&.admin? || record.id == user.id
  end

  def update?
    user&.admin? || record.id == user.id
  end

  def destroy?
    user&.admin? || record.id == user.id
  end

  def create?
    true
  end
end
