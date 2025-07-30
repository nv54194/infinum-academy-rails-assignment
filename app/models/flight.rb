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

  scope :active, -> { where(departs_at: Time.current..) }

  has_many :bookings, dependent: :destroy
  has_many :users, through: :bookings

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

  private

  def departs_before_arrives
    return unless departs_at.present? && arrives_at.present? && departs_at >= arrives_at

    errors.add(:departs_at, 'should be before arrives_at')
  end
end
