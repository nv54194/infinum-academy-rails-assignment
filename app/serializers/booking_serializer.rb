# == Schema Information
#
# Table name: bookings
#
#  id          :bigint           not null, primary key
#  no_of_seats :integer          not null
#  seat_price  :integer          not null
#  user_id     :bigint           not null
#  flight_id   :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class BookingSerializer < Blueprinter::Base
  identifier :id

  fields :no_of_seats, :seat_price, :created_at, :updated_at

  field :total_price do |booking, _|
    booking.no_of_seats * booking.seat_price
  end

  association :user, blueprint: UserSerializer
  association :flight, blueprint: FlightSerializer
end
