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
class Flight < ApplicationRecord
  belongs_to :company
  has_many :bookings, dependent: :destroy
  has_many :users, through: :bookings

  scope :active, -> { where(departs_at: Time.current..) }

  scope :name_cont, lambda { |name|
    where 'LOWER(name) LIKE ?',
          "%#{sanitize_sql_like(name.downcase)}%"
  }

  scope :departs_at_eq, ->(date) { where('DATE(departs_at) = ?', date) }

  scope :no_of_available_seats_gteq, lambda { |min_seats|
    left_joins(:bookings)
      .group('flights.id')
      .having('flights.no_of_seats - COALESCE(SUM(bookings.no_of_seats), 0) >= ?', min_seats)
  }

  scope :overlapping, lambda { |flight|
    where(company_id: flight.company_id)
      .where.not(id: flight.id)
      .where('departs_at < ? AND arrives_at > ?',
             flight.arrives_at, flight.departs_at)
  }

  validates :name,
            presence: true,
            uniqueness: { scope: :company_id, case_sensitive: false }

  validates :departs_at, presence: true
  validates :arrives_at, presence: true
  validate  :departs_before_arrives

  validates :base_price,
            presence: true,
            numericality: { greater_than: 0 }

  validates :no_of_seats,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }

  validate :no_overlapping_flights

  def current_price
    diff = (departs_at.to_date - Date.current).to_i.clamp(0, 15)
    price = if diff >= 15
              base_price
            else
              base_price + (base_price * (15 - diff) / 15.0)
            end
    price.round
  end

  private

  def departs_before_arrives
    return unless departs_at.present? && arrives_at.present? && departs_at >= arrives_at

    errors.add(:departs_at, 'should be before arrives_at')
  end

  def no_overlapping_flights
    return unless company_id.present? && departs_at.present? && arrives_at.present?

    return unless Flight.overlapping(self).exists?

    errors.add(:arrives_at, 'overlaps with another flight from this company')
    errors.add(:departs_at, 'overlaps with another flight from this company')
  end
end
