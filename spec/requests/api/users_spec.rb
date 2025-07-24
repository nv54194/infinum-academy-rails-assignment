require 'rails_helper'

RSpec.describe 'Users API', type: :request do
  include TestHelpers::JsonResponse

  describe 'GET /api/users' do
    let!(:users) { create_list(:user, 3) } # rubocop:disable RSpec/LetSetup

    it 'returns 200 OK and correct number of records' do
      get '/api/users', headers: api_headers
      expect(response).to have_http_status(:ok)
      expect(json_body['users'].size).to eq(3)
    end

    it 'returns users without root when X_API_SERIALIZER header is set to 0' do
      get '/api/users', headers: api_headers(root: 0)
      expect(response).to have_http_status(:ok)
      expect(json_body).to be_an(Array)
      expect(json_body.size).to eq(3)
    end
  end

  describe 'POST /api/users' do
    context 'with valid params' do
      let(:valid_params) do
        {
          user: {
            first_name: 'Ivan',
            last_name: 'Horvat',
            email: 'ivan@example.com'
          }
        }
      end

      it 'returns 201 Created and correct attributes' do
        expect do
          post '/api/users', params: valid_params.to_json, headers: api_headers
        end.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_body['user']).to include(
          'first_name' => valid_params[:user][:first_name],
          'last_name' => valid_params[:user][:last_name],
          'email' => valid_params[:user][:email]
        )
      end
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          user: {
            first_name: '',
            email: ''
          }
        }
      end

      it 'returns 400 Bad Request and error keys' do
        post '/api/users', params: invalid_params.to_json, headers: api_headers

        expect(response).to have_http_status(:bad_request)
        expect(json_body['errors']).to include('first_name', 'email')
      end
    end
  end

  describe 'GET /api/users/:id' do
    let!(:user) do
      create(:user, first_name: 'Nikola', last_name: 'Tesla', email: 'nikola@example.com')
    end

    it 'returns 200 OK and correct attributes' do
      get "/api/users/#{user.id}", headers: api_headers

      expect(response).to have_http_status(:ok)
      expect(json_body['user']).to include(
        'first_name' => user.first_name,
        'last_name' => user.last_name,
        'email' => user.email
      )
    end

    it 'returns jsonapi format when X_API_SERIALIZER_ROOT header is set to jsonapi' do
      get "/api/users/#{user.id}", headers: api_headers(serializer: 'jsonapi')
      expect(response).to have_http_status(:ok)
      expect(json_body['data']).to have_key('attributes')
      expect(json_body['data']['attributes']['first_name']).to eq(user.first_name)
    end
  end

  describe 'PATCH /api/users/:id' do
    let!(:user) do
      create(:user, first_name: 'Petar', last_name: 'Perić', email: 'petar@example.com')
    end

    context 'with valid params' do
      let(:update_params) do
        {
          user: {
            first_name: 'Nikola',
            last_name: 'Tesla'
          }
        }
      end

      it 'returns 200 OK and persists changes' do
        patch "/api/users/#{user.id}", params: update_params.to_json, headers: api_headers

        expect(response).to have_http_status(:ok)
        expect(json_body['user']).to include(
          'first_name' => update_params[:user][:first_name],
          'last_name' => update_params[:user][:last_name]
        )
        user.reload
        expect(user.first_name).to eq(update_params[:user][:first_name])
        expect(user.last_name).to eq(update_params[:user][:last_name])
      end
    end

    context 'with invalid params' do
      let(:invalid_update_params) do
        {
          user: {
            first_name: '',
            email: ''
          }
        }
      end

      it 'returns 400 Bad Request and error keys' do
        patch "/api/users/#{user.id}", params: invalid_update_params.to_json, headers: api_headers

        expect(response).to have_http_status(:bad_request)
        expect(json_body['errors']).to include('first_name', 'email')
      end
    end
  end

  describe 'DELETE /api/users/:id' do
    let!(:user) { create(:user) }

    it 'returns 204 No Content and removes the user' do
      expect do
        delete "/api/users/#{user.id}", headers: api_headers
      end.to change(User, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
