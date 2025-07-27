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
        expect(json_body['booking']['seat_price']).to eq(123)
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

    context 'when authenticated as admin and invalid params' do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let!(:admin) { create(:user, role: :admin) }
      let!(:user) { create(:user) }
      let!(:flight) { create(:flight) }
      let!(:booking) { create(:booking, user: user, flight: flight) }

      it 'returns 400 Bad Request' do
        patch "/api/bookings/#{booking.id}", params: invalid_update_params.to_json,
                                             headers: api_headers(token: admin.token)
        expect(response).to have_http_status(:bad_request)
        expect(json_body['errors'].keys).to include('seat_price', 'no_of_seats')
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
