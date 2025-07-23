class FlightSerializer < Blueprinter::Base
  identifier :id
  fields :name, :no_of_seats, :base_price, :departs_at, :arrives_at
  association :company, blueprint: CompanySerializer
  association :bookings, blueprint: BookingSerializer
  association :users, blueprint: UserSerializer
end
