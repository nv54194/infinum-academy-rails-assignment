require 'rails_helper'

RSpec.describe 'Statistics API - Companies', type: :request do
  include TestHelpers::JsonResponse

  let!(:admin) { create(:user, role: :admin) }

  describe 'GET /api/statistics/companies' do
    it 'returns statistics for a company with correct attributes' do # rubocop:disable RSpec/ExampleLength
      company = create(:company)
      flight1 = create(:flight, company: company, no_of_seats: 10, base_price: 100,
                                departs_at: 1.day.from_now, arrives_at: 2.days.from_now)
      flight2 = create(:flight, company: company, no_of_seats: 5, base_price: 200,
                                departs_at: 3.days.from_now, arrives_at: 4.days.from_now)
      bookings1 = create_list(:booking, 3, flight: flight1, seat_price: 120)
      bookings2 = create_list(:booking, 2, flight: flight2, seat_price: 250)

      get '/api/statistics/companies', headers: api_headers(token: admin.token)
      stats = json_body['companies']
      stat = stats.find { |s| s['company_id'] == company.id }

      total_bookings = bookings1.size + bookings2.size
      total_revenue = bookings1.sum(&:seat_price) + bookings2.sum(&:seat_price)
      average_price = total_bookings.zero? ? 0.0 : total_revenue.to_f / total_bookings

      expect(stat['company_id']).to eq(company.id)
      expect(stat['total_revenue']).to eq(total_revenue)
      expect(stat['total_no_of_booked_seats']).to eq(total_bookings)
      expect(stat['average_price_of_seats']).to eq(average_price)
    end
  end
end
