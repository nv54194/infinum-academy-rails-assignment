RSpec.describe BookingsQuery do
  describe '#result' do
    it 'returns bookings sorted by flight departs_at, flight name, and booking created_at ASC' do # rubocop:disable RSpec/ExampleLength
      flight1 = create(:flight, departs_at: 2.days.from_now, arrives_at: 3.days.from_now,
                                name: 'A')
      flight2 = create(:flight, departs_at: 4.days.from_now, arrives_at: 5.days.from_now,
                                name: 'B')
      booking1 = create(:booking, flight: flight1, created_at: 1.day.ago)
      booking2 = create(:booking, flight: flight1, created_at: 2.days.ago)
      booking3 = create(:booking, flight: flight2, created_at: 3.days.ago)
      sorted = [booking2, booking1, booking3].sort_by do |b|
        [b.flight.departs_at, b.flight.name, b.created_at]
      end
      result = described_class.new(relation: Booking.all).result
      expect(result.map(&:id)).to eq(sorted.map(&:id))
    end

    it 'returns only bookings for active flights when filter=active' do
      flight_active = create(:flight, departs_at: 2.days.from_now, arrives_at: 3.days.from_now)
      flight_other = create(:flight, departs_at: 4.days.from_now, arrives_at: 5.days.from_now)
      booking1 = create(:booking, flight: flight_active, created_at: 1.day.ago)
      booking2 = create(:booking, flight: flight_active, created_at: 2.days.ago)
      booking3 = create(:booking, flight: flight_other, created_at: 3.days.ago)
      result = described_class.new(relation: Booking.all, params: { filter: 'active' }).result
      expect(result.map(&:id)).to contain_exactly(booking1.id, booking2.id, booking3.id)
    end

    it 'returns all bookings when filter is not active' do
      flight1 = create(:flight, departs_at: 2.days.from_now, arrives_at: 3.days.from_now)
      flight2 = create(:flight, departs_at: 4.days.from_now, arrives_at: 5.days.from_now)
      booking1 = create(:booking, flight: flight1, created_at: 1.day.ago)
      booking2 = create(:booking, flight: flight1, created_at: 2.days.ago)
      booking3 = create(:booking, flight: flight2, created_at: 3.days.ago)
      result = described_class.new(relation: Booking.all, params: {}).result
      expect(result.map(&:id)).to contain_exactly(booking1.id, booking2.id, booking3.id)
    end
  end
end
