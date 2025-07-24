require 'rails_helper'

RSpec.describe 'Companies API', type: :request do
  include TestHelpers::JsonResponse

  describe 'GET /api/companies' do
    let!(:companies) { create_list(:company, 3) } # rubocop:disable RSpec/LetSetup

    it 'returns 200 OK and correct number of records' do
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

  describe 'POST /api/companies' do
    context 'with valid params' do
      let(:valid_params) { { company: { name: 'Croatia Airlines' } } }

      it 'returns 201 Created and correct attributes' do
        expect do
          post '/api/companies', params: valid_params.to_json, headers: api_headers
        end.to change(Company, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_body['company']).to include('name' => valid_params[:company][:name])
      end
    end

    context 'with invalid params' do
      let(:invalid_params) { { company: { name: '' } } }

      it 'returns 400 Bad Request and error keys' do
        post '/api/companies', params: invalid_params.to_json, headers: api_headers

        expect(response).to have_http_status(:bad_request)
        expect(json_body['errors']).to include('name')
      end
    end
  end

  describe 'GET /api/companies/:id' do
    let!(:company) { create(:company, name: 'Croatia Airlines') }

    it 'returns 200 OK and correct attributes' do
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

    context 'with valid params' do
      let(:update_params) { { company: { name: 'Updated Name' } } }

      it 'returns 200 OK and persists changes' do
        patch "/api/companies/#{company.id}", params: update_params.to_json, headers: api_headers

        expect(response).to have_http_status(:ok)
        expect(json_body['company']).to include('name' => update_params[:company][:name])
        expect(company.reload.name).to eq(update_params[:company][:name])
      end
    end

    context 'with invalid params' do
      let(:invalid_update_params) { { company: { name: '' } } }

      it 'returns 400 Bad Request and error keys' do
        patch "/api/companies/#{company.id}", params: invalid_update_params.to_json,
                                              headers: api_headers

        expect(response).to have_http_status(:bad_request)
        expect(json_body['errors']).to include('name')
      end
    end
  end

  describe 'DELETE /api/companies/:id' do
    let!(:company) { create(:company) }

    it 'returns 204 No Content and removes the company' do
      expect do
        delete "/api/companies/#{company.id}", headers: api_headers
      end.to change(Company, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
