RSpec.describe 'Companies API', type: :request do
  include TestHelpers::JsonResponse

  describe 'GET /api/companies' do
    context 'with 3 companies' do
      let!(:companies) { create_list(:company, 3) } # rubocop:disable RSpec/LetSetup

      it 'returns 200 OK and correct number of records for unauthenticated user' do
        get '/api/companies', headers: api_headers
        expect(response).to have_http_status(:ok)
        expect(json_body['companies'].size).to eq(3)
      end

      it 'returns companies without root when X_API_SERIALIZER_ROOT header is set to 0' do
        get '/api/companies', headers: api_headers(root: 0)
        expect(response).to have_http_status(:ok)
        expect(json_body).to be_an(Array)
        expect(json_body.size).to eq(3)
      end
    end

    it 'returns companies sorted by name ASC' do
      create(:company, name: 'A')
      create(:company, name: 'B')
      create(:company, name: 'C')
      get '/api/companies', headers: api_headers
      names = json_body['companies'].map { |c| c['name'] }
      expect(names).to eq(names.sort)
    end

    it 'includes correct no_of_active_flights for company' do
      company_active = create(:company, name: 'Active')
      create(:flight, company: company_active, departs_at: 2.days.from_now,
                      arrives_at: 3.days.from_now)
      create(:flight, company: company_active, departs_at: 3.days.from_now,
                      arrives_at: 4.days.from_now)

      get '/api/companies', headers: api_headers
      companies = json_body['companies'].index_by { |c| c['name'] }

      expect(companies['Active']['no_of_active_flights']).to eq(2)
    end

    context 'when filter=active is used' do
      let!(:company_active) { create(:company, name: 'Active') }
      let!(:company_inactive) { create(:company, name: 'Inactive') }
      let!(:future_flight) do # rubocop:disable RSpec/LetSetup
        create(:flight, company: company_active, departs_at: 2.days.from_now,
                        arrives_at: 3.days.from_now)
      end
      let!(:past_flight) do # rubocop:disable RSpec/LetSetup
        create(:flight, company: company_inactive, departs_at: 2.days.ago, arrives_at: 1.day.ago)
      end

      it 'returns only companies with active flights' do
        get '/api/companies?filter=active', headers: api_headers
        names = json_body['companies'].map { |c| c['name'] }
        expect(names).to include('Active')
        expect(names).not_to include('Inactive')
      end

      it 'includes correct no_of_active_flights for each company in filter response' do
        get '/api/companies?filter=active', headers: api_headers
        companies = json_body['companies'].index_by { |c| c['name'] }
        expect(companies['Active']['no_of_active_flights']).to eq(1)
      end
    end
  end

  describe 'POST /api/companies' do
    let(:valid_params) { { company: { name: 'Croatia Airlines' } } }
    let(:invalid_params) { { company: { name: '' } } }

    it 'returns 401 Unauthorized for unauthenticated user' do
      post '/api/companies', params: valid_params.to_json, headers: api_headers
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated as regular user' do
      let!(:user) { create(:user) }

      it 'returns 403 Forbidden' do
        post '/api/companies', params: valid_params.to_json, headers: api_headers(token: user.token)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as admin' do
      let!(:admin) { create(:user, role: :admin) }

      it 'returns 201 Created and correct attributes with valid params' do
        expect do
          post '/api/companies', params: valid_params.to_json,
                                 headers: api_headers(token: admin.token)
        end.to change(Company, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(json_body['company']).to include('name' => valid_params[:company][:name])
      end

      it 'returns 400 Bad Request and error keys with invalid params' do
        post '/api/companies', params: invalid_params.to_json,
                               headers: api_headers(token: admin.token)
        expect(response).to have_http_status(:bad_request)
        expect(json_body['errors']).to include('name')
      end
    end
  end

  describe 'GET /api/companies/:id' do
    let!(:company) { create(:company, name: 'Croatia Airlines') }

    it 'returns 200 OK and correct attributes for unauthenticated user' do
      get "/api/companies/#{company.id}", headers: api_headers
      expect(response).to have_http_status(:ok)
      expect(json_body['company']).to include('name' => company.name)
    end

    it 'returns jsonapi format when X_API_SERIALIZER header is set to jsonapi' do
      get "/api/companies/#{company.id}", headers: api_headers(serializer: 'jsonapi')
      expect(response).to have_http_status(:ok)
      expect(json_body['data']).to have_key('attributes')
      expect(json_body['data']['attributes']['name']).to eq(company.name)
    end
  end

  describe 'PATCH /api/companies/:id' do
    let!(:company) { create(:company, name: 'Old Name') }
    let(:update_params) { { company: { name: 'Updated Name' } } }
    let(:invalid_update_params) { { company: { name: '' } } }

    it 'returns 401 Unauthorized for unauthenticated user' do
      patch "/api/companies/#{company.id}", params: update_params.to_json, headers: api_headers
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated as regular user' do
      let!(:user) { create(:user) }

      it 'returns 403 Forbidden' do
        patch "/api/companies/#{company.id}", params: update_params.to_json,
                                              headers: api_headers(token: user.token)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as admin' do
      let!(:admin) { create(:user, role: :admin) }

      it 'returns 200 OK and persists changes with valid params' do
        patch "/api/companies/#{company.id}", params: update_params.to_json,
                                              headers: api_headers(token: admin.token)
        expect(response).to have_http_status(:ok)
        expect(json_body['company']).to include('name' => update_params[:company][:name])
        expect(company.reload.name).to eq(update_params[:company][:name])
      end

      it 'returns 400 Bad Request and error keys with invalid params' do
        patch "/api/companies/#{company.id}", params: invalid_update_params.to_json,
                                              headers: api_headers(token: admin.token)
        expect(response).to have_http_status(:bad_request)
        expect(json_body['errors']).to include('name')
      end
    end
  end

  describe 'DELETE /api/companies/:id' do
    let!(:company) { create(:company) }

    it 'returns 401 Unauthorized for unauthenticated user' do
      delete "/api/companies/#{company.id}", headers: api_headers
      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated as regular user' do
      let!(:user) { create(:user) }

      it 'returns 403 Forbidden' do
        delete "/api/companies/#{company.id}", headers: api_headers(token: user.token)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as admin' do
      let!(:admin) { create(:user, role: :admin) }

      it 'returns 204 No Content and removes the company' do
        expect do
          delete "/api/companies/#{company.id}", headers: api_headers(token: admin.token)
        end.to change(Company, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
