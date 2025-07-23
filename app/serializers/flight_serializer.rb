class FlightSerializer < Blueprinter::Base
  identifier :id

  fields :name,
         :no_of_seats,
         :base_price,
         :departs_at,
         :arrives_at,
         :created_at,
         :updated_at

  association :company, blueprint: CompanySerializer
  # posebni viewovi za razlicite uloge?
  # association :bookings, blueprint: BookingSerializer
  # association :users, blueprint: UserSerializer
end
