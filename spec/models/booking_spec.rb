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
require 'rails_helper'

RSpec.describe Booking, type: :model do
  subject { build(:booking) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:flight) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:seat_price) }
    it { is_expected.to validate_numericality_of(:seat_price).is_greater_than(0) }

    it { is_expected.to validate_presence_of(:no_of_seats) }
    it { is_expected.to validate_numericality_of(:no_of_seats).is_greater_than(0) }
  end

  describe 'validation of flight_not_in_past' do
    subject(:booking) { build(:booking, flight: flight) }

    let(:flight) { build(:flight, departs_at: 1.day.ago) }

    it 'is not valid if flight departs in the past' do
      expect(booking).not_to be_valid
      expect(booking.errors[:flight]).to include('should not be in the past')
    end

    it 'is valid if flight departs in the future' do
      booking.flight.departs_at = 1.day.from_now
      expect(booking).to be_valid
    end
  end
end
