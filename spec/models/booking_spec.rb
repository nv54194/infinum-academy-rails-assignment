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

RSpec.describe Booking, type: :model do
  subject { build(:booking) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:flight) }
  end

  describe 'seat_price validations' do
    it { is_expected.to validate_presence_of(:seat_price) }
    it { is_expected.to validate_numericality_of(:seat_price).is_greater_than(0) }
  end

  describe 'no_of_seats validations' do
    it { is_expected.to validate_presence_of(:no_of_seats) }
    it { is_expected.to validate_numericality_of(:no_of_seats).only_integer.is_greater_than(0) }
  end

  describe 'validation of flight_not_in_past' do
    subject(:booking) { build(:booking, flight: flight) }

    let(:flight) { build(:flight, departs_at: departs_at) }

    context 'when departs_at is in the past' do
      let(:departs_at) { 1.day.ago }

      it 'is not valid' do
        expect(booking).not_to be_valid
        expect(booking.errors[:flight]).to include('should not be in the past')
      end
    end

    context 'when departs_at is in the future' do
      let(:departs_at) { 1.day.from_now }

      it 'is valid' do
        expect(booking).to be_valid
      end
    end
  end

  describe 'overbooking validation' do
    it 'is invalid if total booked seats exceed flight capacity' do
      flight = create(:flight, no_of_seats: 2)
      create(:booking, flight: flight, no_of_seats: 2)
      overbooking = build(:booking, flight: flight, no_of_seats: 1)
      expect(overbooking).not_to be_valid
      expect(overbooking.errors[:no_of_seats]).to include('is more than available seats for this flight')
    end

    it 'is valid if total booked seats do not exceed flight capacity' do
      flight = create(:flight, no_of_seats: 3)
      create(:booking, flight: flight, no_of_seats: 2)
      booking = build(:booking, flight: flight, no_of_seats: 1)
      expect(booking).to be_valid
    end
  end
end
