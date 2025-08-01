require 'rails_helper'

RSpec.describe 'Statistics API - Flights', type: :request do
  include TestHelpers::JsonResponse

  let!(:admin) { create(:user, role: :admin) }

  describe 'GET /api/statistics/flights' do
    it 'returns statistics for a flight with correct attributes' do
      company = create(:company)
      flight = create(:flight, company: company, no_of_seats: 10, base_price: 100)
      bookings = create_list(:booking, 3, flight: flight, seat_price: 120)
      get '/api/statistics/flights', headers: api_headers(token: admin.token)
      stats = json_body['flights']
      stat = stats.first

      expect(stat['flight_id']).to eq(flight.id)
      expect(stat['revenue']).to eq(bookings.sum(&:seat_price))
      expect(stat['no_of_booked_seats']).to eq(bookings.size)
      expect(stat['occupancy']).to eq((bookings.size.to_f / flight.no_of_seats) * 100)
    end
  end
end
