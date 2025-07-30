class SessionSerializer < Blueprinter::Base
  field :token
  association :user, blueprint: UserSerializer
end
