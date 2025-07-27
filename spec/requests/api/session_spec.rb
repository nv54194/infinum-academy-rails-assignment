RSpec.describe 'Sessions API', type: :request do
  include TestHelpers::JsonResponse

  let!(:user) { create(:user, email: 'example@example.com', password: 'password') }

  describe 'POST /api/session' do
    context 'with valid credentials' do
      let(:params) do
        {
          session: {
            email: 'example@example.com',
            password: 'password'
          }
        }
      end

      it 'returns 201 Created, token and user info' do
        post '/api/session', params: params.to_json, headers: api_headers

        expect(response).to have_http_status(:created)
        expect(json_body['session']['token']).to eq(user.reload.token)
        expect(json_body['session']['user']['id']).to eq(user.id)
        expect(json_body['session']['user']['email']).to eq(user.email)
      end
    end

    context 'with invalid password' do
      let(:params) do
        {
          session: {
            email: 'example@example.com',
            password: 'wrong'
          }
        }
      end

      it 'returns 401 Unauthorized and error' do
        post '/api/session', params: params.to_json, headers: api_headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_body['errors']).to include('credentials')
      end
    end

    context 'with invalid email' do
      let(:params) do
        {
          session: {
            email: 'not.exists@example.com',
            password: 'password'
          }
        }
      end

      it 'returns 401 Unauthorized and error' do
        post '/api/session', params: params.to_json, headers: api_headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_body['errors']).to include('credentials')
      end
    end

    context 'with missing params' do
      it 'returns 400 Bad Request' do
        post '/api/session', params: {}.to_json, headers: api_headers

        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe 'DELETE /api/session' do
    context 'with valid token' do
      it 'returns 204 No Content and regenerates token' do
        old_token = user.token
        delete '/api/session', headers: api_headers(token: user.token)

        expect(response).to have_http_status(:no_content)
        expect(user.reload.token).not_to be_nil
        expect(user.token).not_to eq(old_token)
      end
    end

    context 'with invalid token' do
      it 'returns 401 Unauthorized and error' do
        delete '/api/session', headers: api_headers(token: 'invalidtoken')

        expect(response).to have_http_status(:unauthorized)
        expect(json_body['errors']).to include('token')
      end
    end
  end
end
