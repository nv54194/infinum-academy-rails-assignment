# == Schema Information
#
# Table name: bookings
#
#  id          :bigint           not null, primary key
#  no_of_seats :integer          not null
#  seat_price  :integer          not null
#  user_id     :integer          not null
#  flight_id   :integer          not null
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
            numericality: { greater_than: 0 }

  validate :flight_not_in_past

  private

  def flight_not_in_past
    return unless flight&.departs_at.present? && flight.departs_at < DateTime.current

    errors.add(:flight, 'should not be in the past')
  end
end
