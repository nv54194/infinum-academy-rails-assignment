RSpec.describe 'Bookings API', type: :request do
  include TestHelpers::JsonResponse

  describe 'GET /api/bookings' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized' do
        get '/api/bookings', headers: api_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as regular user' do
      let!(:user) { create(:user) }
      let!(:user_bookings) { create_list(:booking, 2, user: user) } # rubocop:disable RSpec/LetSetup
      let!(:other_bookings) { create_list(:booking, 2) } # rubocop:disable RSpec/LetSetup

      it 'returns only user\'s own bookings' do
        get '/api/bookings', headers: api_headers(token: user.token)
        expect(response).to have_http_status(:ok)
        expect(json_body['bookings'].size).to eq(2)
        expect(json_body['bookings'].all? { |b| b['user']['id'] == user.id }).to be true
      end
    end

    context 'when authenticated as admin' do
      let!(:admin) { create(:user, role: :admin) }
      let!(:user) { create(:user) }
      let!(:other_user) { create(:user) }
      let!(:user_bookings) { create_list(:booking, 2, user: user) } # rubocop:disable RSpec/LetSetup
      let!(:other_bookings) { create_list(:booking, 2, user: other_user) } # rubocop:disable RSpec/LetSetup

      it 'returns all bookings' do
        get '/api/bookings', headers: api_headers(token: admin.token)
        expect(response).to have_http_status(:ok)
        expect(json_body['bookings'].size).to eq(4)
      end
    end

    it 'returns bookings sorted by [departs_at, name, created_at] ASC in index response' do # rubocop:disable RSpec/ExampleLength
      user = create(:user)
      flight_a = create(:flight, name: 'A', departs_at: 2.days.from_now)
      flight_b = create(:flight, name: 'B', departs_at: 1.day.from_now)
      flight_c = create(:flight, name: 'C', departs_at: 3.days.from_now)
      booking_a = create(:booking, user: user, flight: flight_a, created_at: 3.days.ago)
      booking_b = create(:booking, user: user, flight: flight_b, created_at: 2.days.ago)
      booking_c = create(:booking, user: user, flight: flight_c, created_at: 1.day.ago)

      get '/api/bookings', headers: api_headers(token: user.token)
      bookings = json_body['bookings']

      expected = [booking_a, booking_b, booking_c].sort_by do |b|
        [b.flight.departs_at, b.flight.name, b.created_at]
      end
      actual = bookings.sort_by do |b|
        [b['flight']['departs_at'], b['flight']['name'], b['created_at']]
      end

      expect(actual.map { |b| b['id'] }).to eq(expected.map(&:id))
    end

    it 'returns only bookings for active flights' do
      user = create(:user)
      future_flight = create(:flight, departs_at: 2.days.from_now)
      create(:booking, user: user, flight: future_flight)

      get '/api/bookings', params: { filter: 'active' }, headers: api_headers(token: user.token)
      flight_ids = json_body['bookings'].map { |b| b['flight']['id'] }
      expect(flight_ids).to include(future_flight.id)
    end

    it 'includes total_price for each booking' do
      user = create(:user)
      flight = create(:flight)
      booking = create(:booking, user: user, flight: flight, no_of_seats: 3, seat_price: 100)
      get '/api/bookings', headers: api_headers(token: user.token)
      booking_json = json_body['bookings'].find { |b| b['id'] == booking.id }
      expect(booking_json['total_price']).to eq(300)
    end
  end

  describe 'POST /api/bookings' do
    let!(:flight) { create(:flight) }
    let(:valid_params) do
      {
        booking: {
          seat_price: 100,
          no_of_seats: 2,
          flight_id: flight.id
        }
      }
    end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized' do
        post '/api/bookings', params: valid_params.to_json, headers: api_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as regular user with valid params' do
      let!(:user) { create(:user) }
      let!(:admin) { create(:user, role: :admin) }
      let(:valid_params) do
        {
          booking: {
            seat_price: 100,
            no_of_seats: 2,
            flight_id: flight.id
          }
        }
      end

      it 'creates booking for current user (ignores user_id param)' do
        params_with_user_id = valid_params.deep_merge(booking: { user_id: admin.id })
        expect do
          post '/api/bookings', params: params_with_user_id.to_json,
                                headers: api_headers(token: user.token)
        end.to change(Booking, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(json_body['booking']['user']['id']).to eq(user.id)
      end
    end

    context 'when authenticated as regular user with invalid params' do
      let!(:user) { create(:user) }
      let(:invalid_params) do
        {
          booking: {
            seat_price: nil,
            no_of_seats: nil,
            flight_id: nil
          }
        }
      end

      it 'returns 400 Bad Request' do
        post '/api/bookings', params: invalid_params.to_json,
                              headers: api_headers(token: user.token)
        expect(response).to have_http_status(:bad_request)
        expect(json_body['errors'].keys).to include('seat_price', 'no_of_seats', 'flight')
      end
    end

    context 'when authenticated as admin with invalid params' do
      let!(:admin) { create(:user, role: :admin) }
      let(:invalid_params) do
        {
          booking: {
            seat_price: nil,
            no_of_seats: nil,
            flight_id: nil
          }
        }
      end

      it 'returns 400 Bad Request' do
        post '/api/bookings', params: invalid_params.to_json,
                              headers: api_headers(token: admin.token)
        expect(response).to have_http_status(:bad_request)
        expect(json_body['errors'].keys).to include('seat_price', 'no_of_seats', 'flight')
      end
    end
  end

  describe 'GET /api/bookings/:id' do
    let!(:flight) { create(:flight) }
    let!(:user) { create(:user) }
    let!(:booking) { create(:booking, user: user, flight: flight) }

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized' do
        get "/api/bookings/#{booking.id}", headers: api_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as owner' do
      it 'shows own booking' do
        get "/api/bookings/#{booking.id}", headers: api_headers(token: user.token)
        expect(response).to have_http_status(:ok)
        expect(json_body['booking']['id']).to eq(booking.id)
      end
    end

    context 'when authenticated as admin' do
      let!(:admin) { create(:user, role: :admin) }

      it 'shows any booking' do
        get "/api/bookings/#{booking.id}", headers: api_headers(token: admin.token)
        expect(response).to have_http_status(:ok)
        expect(json_body['booking']['id']).to eq(booking.id)
      end
    end

    context 'when authenticated as other user' do
      let!(:other_user) { create(:user) }

      it 'returns 403 Forbidden' do
        get "/api/bookings/#{booking.id}", headers: api_headers(token: other_user.token)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'PATCH /api/bookings/:id' do
    let(:update_params) { { booking: { seat_price: 200, no_of_seats: 3 } } }
    let(:invalid_update_params) { { booking: { seat_price: nil, no_of_seats: nil } } }

    context 'when unauthenticated' do
      let!(:user) { create(:user) }
      let!(:flight) { create(:flight) }
      let!(:booking) { create(:booking, user: user, flight: flight) }

      it 'returns 401 Unauthorized' do
        patch "/api/bookings/#{booking.id}", params: update_params.to_json, headers: api_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as owner and valid params' do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let!(:user) { create(:user) }
      let!(:other_user) { create(:user) }
      let!(:flight) { create(:flight) }
      let!(:booking) { create(:booking, user: user, flight: flight) }

      it 'updates own booking but not user_id' do
        params = { booking: { user_id: other_user.id, seat_price: 123 } }
        patch "/api/bookings/#{booking.id}",
              params: params.to_json,
              headers: api_headers(token: user.token)
        expect(response).to have_http_status(:ok)
        expect(json_body['booking']['user']['id']).to eq(user.id)
        expect(json_body['booking']['seat_price']).to eq(params[:booking][:seat_price])
      end
    end

    context 'when authenticated as owner and invalid params' do
      let!(:user) { create(:user) }
      let!(:flight) { create(:flight) }
      let!(:booking) { create(:booking, user: user, flight: flight) }

      it 'returns 400 Bad Request' do
        patch "/api/bookings/#{booking.id}", params: invalid_update_params.to_json,
                                             headers: api_headers(token: user.token)
        expect(response).to have_http_status(:bad_request)
        expect(json_body['errors'].keys).to include('seat_price', 'no_of_seats')
      end
    end

    context 'when authenticated as admin and valid params' do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let!(:admin) { create(:user, role: :admin) }
      let!(:user) { create(:user) }
      let!(:other_user) { create(:user) }
      let!(:flight) { create(:flight) }
      let!(:booking) { create(:booking, user: user, flight: flight) }

      it 'updates any booking and user_id' do
        patch "/api/bookings/#{booking.id}",
              params: { booking: { user_id: other_user.id } }.to_json,
              headers: api_headers(token: admin.token)
        expect(response).to have_http_status(:ok)
        expect(json_body['booking']['user']['id']).to eq(other_user.id)
      end
    end

    context 'when authenticated as other user' do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let!(:user) { create(:user) }
      let!(:other_user) { create(:user) }
      let!(:flight) { create(:flight) }
      let!(:booking) { create(:booking, user: user, flight: flight) }

      it 'returns 403 Forbidden' do
        patch "/api/bookings/#{booking.id}", params: update_params.to_json,
                                             headers: api_headers(token: other_user.token)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /api/bookings/:id' do
    context 'when unauthenticated' do
      let!(:user) { create(:user) }
      let!(:flight) { create(:flight) }
      let!(:booking) { create(:booking, user: user, flight: flight) }

      it 'returns 401 Unauthorized' do
        delete "/api/bookings/#{booking.id}", headers: api_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as owner' do
      let!(:user) { create(:user) }
      let!(:flight) { create(:flight) }
      let!(:booking) { create(:booking, user: user, flight: flight) }

      it 'removes own booking' do
        expect do
          delete "/api/bookings/#{booking.id}", headers: api_headers(token: user.token)
        end.to change(Booking, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when authenticated as admin' do
      let!(:admin) { create(:user, role: :admin) }
      let!(:user) { create(:user) }
      let!(:flight) { create(:flight) }
      let!(:booking) { create(:booking, user: user, flight: flight) }

      it 'removes any booking' do
        expect do
          delete "/api/bookings/#{booking.id}", headers: api_headers(token: admin.token)
        end.to change(Booking, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when authenticated as other user' do
      let!(:user) { create(:user) }
      let!(:other_user) { create(:user) }
      let!(:flight) { create(:flight) }
      let!(:booking) { create(:booking, user: user, flight: flight) }

      it 'returns 403 Forbidden' do
        delete "/api/bookings/#{booking.id}", headers: api_headers(token: other_user.token)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
