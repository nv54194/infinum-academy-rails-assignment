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
class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :flight

  validates :seat_price,
            presence: true,
            numericality: { greater_than: 0 }

  validates :no_of_seats,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }

  validate :flight_not_in_past
  validate :not_overbooked

  private

  def flight_not_in_past
    return unless flight&.departs_at.present? && flight.departs_at < DateTime.current

    errors.add(:flight, 'should not be in the past')
  end

  def not_overbooked
    return unless flight

    total_seats = flight.bookings.sum(:no_of_seats) + no_of_seats
    return unless total_seats > flight.no_of_seats

    errors.add(:no_of_seats, 'is more than available seats for this flight')
  end
end
