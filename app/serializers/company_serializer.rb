class CompanySerializer < Blueprinter::Base
  identifier :id
  fields :name
  association :flights, blueprint: FlightSerializer
end
