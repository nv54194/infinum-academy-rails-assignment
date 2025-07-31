# == Schema Information
#
# Table name: flights
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  no_of_seats :integer
#  base_price  :integer          not null
#  departs_at  :datetime         not null
#  arrives_at  :datetime         not null
#  company_id  :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class FlightSerializer < Blueprinter::Base
  identifier :id

  fields :name,
         :no_of_seats,
         :base_price,
         :departs_at,
         :arrives_at,
         :created_at,
         :updated_at

  field :no_of_booked_seats do |flight, _|
    flight.bookings.sum(:no_of_seats)
  end

  field :company_name do |flight, _|
    flight.company&.name
  end

  field :current_price do |flight, _|
    diff = (flight.departs_at.to_date - Date.current).to_i
    price = if diff >= 15
              flight.base_price
            else
              flight.base_price + (flight.base_price * (15 - diff) / 15.0)
            end
    price.round
  end

  association :company, blueprint: CompanySerializer
end
