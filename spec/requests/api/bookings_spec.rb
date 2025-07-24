RSpec.describe 'Bookings API', type: :request do
  include TestHelpers::JsonResponse

  describe 'GET /api/bookings' do
    let!(:bookings) { create_list(:booking, 3) } # rubocop:disable RSpec/LetSetup

    it 'returns 200 OK and correct number of records' do
      get '/api/bookings', headers: api_headers
      expect(response).to have_http_status(:ok)
      expect(json_body['bookings'].size).to eq(3)
    end
  end

  describe 'POST /api/bookings' do
    let!(:user)   { create(:user) }
    let!(:flight) { create(:flight) }

    context 'with valid params' do
      let(:valid_params) do
        {
          booking: {
            seat_price: 100,
            no_of_seats: 2,
            user_id: user.id,
            flight_id: flight.id
          }
        }
      end

      it 'returns 201 Created and correct attributes' do
        expect do
          post '/api/bookings', params: valid_params.to_json, headers: api_headers
        end.to change(Booking, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_body['booking']).to include(
          'seat_price' => valid_params[:booking][:seat_price],
          'no_of_seats' => valid_params[:booking][:no_of_seats]
        )
        expect(json_body['booking']['user']).to include('id' => user.id)
        expect(json_body['booking']['flight']).to include('id' => flight.id)
      end
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          booking: {
            seat_price: nil,
            no_of_seats: nil,
            user_id: nil,
            flight_id: nil
          }
        }
      end

      it 'returns 400 Bad Request and error keys' do
        post '/api/bookings', params: invalid_params.to_json, headers: api_headers

        expect(response).to have_http_status(:bad_request)
        expect(json_body['errors']).to include('seat_price', 'no_of_seats', 'user', 'flight')
      end
    end
  end

  describe 'GET /api/bookings/:id' do
    let!(:booking) { create(:booking) }

    it 'returns 200 OK and correct attributes' do
      get "/api/bookings/#{booking.id}", headers: api_headers

      expect(response).to have_http_status(:ok)
      expect(json_body['booking']).to include(
        'seat_price' => booking.seat_price,
        'no_of_seats' => booking.no_of_seats
      )
      expect(json_body['booking']['user']).to include('id' => booking.user_id)
      expect(json_body['booking']['flight']).to include('id' => booking.flight_id)
    end
  end

  describe 'PATCH /api/bookings/:id' do
    let!(:booking) { create(:booking) }

    context 'with valid params' do
      let(:update_params) do
        {
          booking: {
            seat_price: 200,
            no_of_seats: 3
          }
        }
      end

      it 'returns 200 OK and persists changes' do
        patch "/api/bookings/#{booking.id}", params: update_params.to_json, headers: api_headers

        expect(response).to have_http_status(:ok)
        expect(json_body['booking']).to include(
          'seat_price' => update_params[:booking][:seat_price],
          'no_of_seats' => update_params[:booking][:no_of_seats]
        )
        booking.reload
        expect(booking.seat_price).to eq(update_params[:booking][:seat_price])
        expect(booking.no_of_seats).to eq(update_params[:booking][:no_of_seats])
      end
    end

    context 'with invalid params' do
      let(:invalid_update_params) do
        {
          booking: {
            seat_price: nil,
            no_of_seats: nil
          }
        }
      end

      it 'returns 400 Bad Request and error keys' do
        patch "/api/bookings/#{booking.id}", params: invalid_update_params.to_json,
                                             headers: api_headers

        expect(response).to have_http_status(:bad_request)
        expect(json_body['errors']).to include('seat_price', 'no_of_seats')
      end
    end
  end

  describe 'DELETE /api/bookings/:id' do
    let!(:booking) { create(:booking) }

    it 'returns 204 No Content and removes the booking' do
      expect do
        delete "/api/bookings/#{booking.id}", headers: api_headers
      end.to change(Booking, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
