RSpec.describe 'Flights API', type: :request do
  include TestHelpers::JsonResponse

  describe 'GET /api/flights' do
    let!(:flights) { create_list(:flight, 3) } # rubocop:disable RSpec/LetSetup

    it 'returns 200 OK and correct number of records for unauthenticated user' do
      get '/api/flights', headers: api_headers
      expect(response).to have_http_status(:ok)
      expect(json_body['flights'].size).to eq(3)
    end

    it 'returns flights without root when X_API_SERIALIZER_ROOT header is set to 0' do
      get '/api/flights', headers: api_headers(root: 0)
      expect(response).to have_http_status(:ok)
      expect(json_body).to be_an(Array)
      expect(json_body.size).to eq(3)
    end

    describe 'advanced features' do
      it 'returns only active flights in index' do # rubocop:disable RSpec/ExampleLength
        company = create(:company)
        other_company = create(:company)
        active_flight = create(:flight, company: company, departs_at: 2.days.from_now,
                                        arrives_at: 3.days.from_now, created_at: 1.day.ago)
        inactive_flight = create(:flight, company: company, departs_at: 2.days.ago,
                                          arrives_at: 1.day.ago, created_at: 3.days.ago)
        other_flight = create(:flight, company: other_company, departs_at: 5.days.from_now,
                                       arrives_at: 6.days.from_now, created_at: 2.days.ago)

        get '/api/flights', headers: api_headers
        ids = json_body['flights'].map { |f| f['id'] }
        expect(ids).to include(active_flight.id, other_flight.id)
        expect(ids).not_to include(inactive_flight.id)
      end

      it 'returns flights sorted by departs_at, name, created_at ASC' do
        company = create(:company)
        create(:flight, company: company, departs_at: 2.days.from_now, arrives_at: 3.days.from_now,
                        name: 'A', created_at: 1.day.ago)
        create(:flight, company: company, departs_at: 5.days.from_now, arrives_at: 6.days.from_now,
                        name: 'B', created_at: 2.days.ago)
        get '/api/flights', headers: api_headers
        flights = json_body['flights']
        sorted = flights.sort_by { |f| [f['departs_at'], f['name'], f['created_at']] }
        expect(flights.map { |f| f['id'] }).to eq(sorted.map { |f| f['id'] })
      end

      it 'filters by name (contains, case insensitive)' do
        company = create(:company)
        create(:flight, name: 'A', company: company, departs_at: 1.day.from_now,
                        arrives_at: 2.days.from_now)
        create(:flight, name: 'B', company: company, departs_at: 3.days.from_now,
                        arrives_at: 4.days.from_now)
        create(:flight, name: 'C', company: company, departs_at: 5.days.from_now,
                        arrives_at: 6.days.from_now)

        get '/api/flights', params: { name_cont: 'a' }, headers: api_headers
        names = json_body['flights'].map { |f| f['name'].downcase }
        expect(names.all? { |n| n.include?('a') }).to be true
      end

      it 'filters by departs_at' do
        company = create(:company)
        flight = create(:flight, company: company, departs_at: 2.days.from_now.change(sec: 0))
        create(:flight, company: company, departs_at: 3.days.from_now)

        date = flight.departs_at
        get '/api/flights', params: { departs_at_eq: date }, headers: api_headers
        ids = json_body['flights'].map { |f| f['id'] }
        expect(ids).to include(flight.id)
      end

      it 'filters by number of available seats (>=)' do
        company = create(:company)
        flight = create(:flight, company: company, no_of_seats: 10, departs_at: 1.day.from_now,
                                 arrives_at: 2.days.from_now)
        create_list(:booking, 5, flight: flight)
        create(:flight, company: company, no_of_seats: 3, departs_at: 3.days.from_now,
                        arrives_at: 4.days.from_now)

        get '/api/flights', params: { no_of_available_seats_gteq: 5 }, headers: api_headers
        ids = json_body['flights'].map { |f| f['id'] }
        expect(ids).to include(flight.id)
      end
    end
  end

  describe 'POST /api/flights' do
    let!(:company) { create(:company) }
    let(:valid_params) do
      {
        flight: {
          name: 'Flight 101',
          no_of_seats: 201,
          base_price: 199,
          departs_at: 2.days.from_now,
          arrives_at: 3.days.from_now,
          company_id: company.id
        }
      }
    end
    let(:invalid_params) do
      {
        flight: {
          name: '',
          no_of_seats: nil,
          base_price: nil,
          departs_at: nil,
          arrives_at: nil,
          company_id: nil
        }
      }
    end

    it 'returns 401 Unauthorized for unauthenticated user' do
      post '/api/flights', params: valid_params.to_json, headers: api_headers
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated as regular user' do
      let!(:user) { create(:user) }

      it 'returns 403 Forbidden' do
        post '/api/flights', params: valid_params.to_json, headers: api_headers(token: user.token)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as admin' do
      let!(:admin) { create(:user, role: :admin) }

      it 'creates a flight and returns 201 Created' do
        expect do
          post '/api/flights', params: valid_params.to_json,
                               headers: api_headers(token: admin.token)
        end.to change(Flight, :count).by(1)
        expect(response).to have_http_status(:created)
      end

      it 'returns correct attributes for the created flight' do
        post '/api/flights', params: valid_params.to_json,
                             headers: api_headers(token: admin.token)
        expect(json_body['flight']).to include(
          'name' => valid_params[:flight][:name],
          'no_of_seats' => valid_params[:flight][:no_of_seats],
          'base_price' => valid_params[:flight][:base_price]
        )
        expect(json_body['flight']['company']).to include('id' => company.id)
      end

      it 'returns 400 Bad Request and error keys with invalid params' do
        post '/api/flights', params: invalid_params.to_json,
                             headers: api_headers(token: admin.token)
        expect(response).to have_http_status(:bad_request)
        expect(json_body['errors']).to include('name', 'no_of_seats', 'base_price', 'departs_at',
                                               'arrives_at', 'company')
      end
    end
  end

  describe 'GET /api/flights/:id' do
    let!(:company) { create(:company) }
    let!(:flight) do
      create(:flight, name: 'Flight 777', no_of_seats: 100, base_price: 150, company: company)
    end

    it 'returns 200 OK and correct attributes for unauthenticated user' do
      get "/api/flights/#{flight.id}", headers: api_headers
      expect(response).to have_http_status(:ok)
      expect(json_body['flight']).to include(
        'name' => flight.name,
        'no_of_seats' => flight.no_of_seats,
        'base_price' => flight.base_price
      )
      expect(json_body['flight']['company']).to include('id' => company.id)
    end

    it 'returns jsonapi format when X_API_SERIALIZER header is set to jsonapi' do
      get "/api/flights/#{flight.id}", headers: api_headers(serializer: 'jsonapi')
      expect(response).to have_http_status(:ok)
      expect(json_body['data']).to have_key('attributes')
      expect(json_body['data']['attributes']['name']).to eq(flight.name)
      expect(json_body['data']['attributes']['no_of_seats']).to eq(flight.no_of_seats)
      expect(json_body['data']['attributes']['base_price']).to eq(flight.base_price)
    end
  end

  describe 'PATCH /api/flights/:id' do
    let!(:company) { create(:company) }
    let!(:flight) do
      create(:flight, name: 'Old Flight', no_of_seats: 80, base_price: 100, company: company)
    end
    let(:update_params) do
      {
        flight: {
          name: 'Updated Flight',
          no_of_seats: 120,
          base_price: 250,
          company_id: company.id
        }
      }
    end
    let(:invalid_update_params) do
      {
        flight: {
          name: '',
          no_of_seats: nil,
          base_price: nil,
          company_id: nil
        }
      }
    end

    it 'returns 401 Unauthorized for unauthenticated user' do
      patch "/api/flights/#{flight.id}", params: update_params.to_json, headers: api_headers
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated as regular user' do
      let!(:user) { create(:user) }

      it 'returns 403 Forbidden' do
        patch "/api/flights/#{flight.id}", params: update_params.to_json,
                                           headers: api_headers(token: user.token)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as admin' do
      let!(:admin) { create(:user, role: :admin) }

      it 'returns 200 OK and correct attributes' do
        patch "/api/flights/#{flight.id}", params: update_params.to_json,
                                           headers: api_headers(token: admin.token)
        expect(response).to have_http_status(:ok)
        expect(json_body['flight']).to include(
          'name' => update_params[:flight][:name],
          'no_of_seats' => update_params[:flight][:no_of_seats],
          'base_price' => update_params[:flight][:base_price]
        )
        expect(json_body['flight']['company']).to include('id' => company.id)
      end

      it 'returns 400 Bad Request and error keys with invalid params' do
        patch "/api/flights/#{flight.id}", params: invalid_update_params.to_json,
                                           headers: api_headers(token: admin.token)
        expect(response).to have_http_status(:bad_request)
        expect(json_body['errors']).to include('name', 'no_of_seats', 'base_price', 'company')
      end
    end
  end

  describe 'DELETE /api/flights/:id' do
    let!(:company) { create(:company) }
    let!(:flight) { create(:flight, company: company) }

    it 'returns 401 Unauthorized for unauthenticated user' do
      delete "/api/flights/#{flight.id}", headers: api_headers
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated as regular user' do
      let!(:user) { create(:user) }

      it 'returns 403 Forbidden' do
        delete "/api/flights/#{flight.id}", headers: api_headers(token: user.token)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as admin' do
      let!(:admin) { create(:user, role: :admin) }

      it 'returns 204 No Content and removes the flight' do
        expect do
          delete "/api/flights/#{flight.id}", headers: api_headers(token: admin.token)
        end.to change(Flight, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
