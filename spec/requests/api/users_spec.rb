RSpec.describe 'Users API', type: :request do
  include TestHelpers::JsonResponse

  describe 'GET /api/users' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized' do
        get '/api/users', headers: api_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as regular user' do
      let!(:user) { create(:user) }

      it 'returns 403 Forbidden' do
        get '/api/users', headers: api_headers(token: user.token)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as admin' do
      let!(:admin) { create(:user, role: :admin) }
      let!(:users) { create_list(:user, 3) } # rubocop:disable RSpec/LetSetup

      it 'returns 200 OK and correct number of records' do
        get '/api/users', headers: api_headers(token: admin.token)
        expect(response).to have_http_status(:ok)
        expect(json_body['users'].size).to eq(4)
      end

      it 'returns users without root when X_API_SERIALIZER header is set to 0' do
        get '/api/users', headers: api_headers(root: 0, token: admin.token)
        expect(response).to have_http_status(:ok)
        expect(json_body).to be_an(Array)
        expect(json_body.size).to eq(4)
      end
    end
  end

  describe 'POST /api/users' do
    context 'with valid params' do
      let(:valid_params) do
        {
          user: {
            first_name: 'Example',
            last_name: 'User',
            email: 'example.user@example.com',
            password: 'password'
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
            email: '',
            password: ''
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
    let!(:target_user) do
      create(:user, first_name: 'Example', last_name: 'User', email: 'example.user@example.com')
    end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized' do
        get "/api/users/#{target_user.id}", headers: api_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as other user' do
      let!(:other_user) { create(:user) }

      it 'returns 403 Forbidden' do
        get "/api/users/#{target_user.id}", headers: api_headers(token: other_user.token)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as self' do
      it 'returns 200 OK and correct attributes' do
        get "/api/users/#{target_user.id}", headers: api_headers(token: target_user.token)
        expect(response).to have_http_status(:ok)
        expect(json_body['user']).to include(
          'first_name' => target_user.first_name,
          'last_name' => target_user.last_name,
          'email' => target_user.email
        )
      end

      it 'returns jsonapi format when X_API_SERIALIZER_ROOT header is set to jsonapi' do
        get "/api/users/#{target_user.id}",
            headers: api_headers(serializer: 'jsonapi', token: target_user.token)
        expect(response).to have_http_status(:ok)
        expect(json_body['data']).to have_key('attributes')
        expect(json_body['data']['attributes']['first_name']).to eq(target_user.first_name)
      end
    end

    context 'when authenticated as admin' do
      let!(:admin) { create(:user, role: :admin) }

      it 'returns 200 OK and correct attributes' do
        get "/api/users/#{target_user.id}", headers: api_headers(token: admin.token)
        expect(response).to have_http_status(:ok)
        expect(json_body['user']).to include(
          'first_name' => target_user.first_name,
          'last_name' => target_user.last_name,
          'email' => target_user.email
        )
      end
    end
  end

  describe 'PATCH /api/users/:id' do
    let!(:target_user) do
      create(:user, first_name: 'Example', last_name: 'User', email: 'example.user@example.com')
    end
    let(:update_params) do
      {
        user: {
          first_name: 'Updated',
          last_name: 'Example'
        }
      }
    end
    let(:invalid_update_params) do
      {
        user: {
          first_name: '',
          email: ''
        }
      }
    end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized' do
        patch "/api/users/#{target_user.id}", params: update_params.to_json, headers: api_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as other user' do
      let!(:other_user) { create(:user) }

      it 'returns 403 Forbidden' do
        patch "/api/users/#{target_user.id}", params: update_params.to_json,
                                              headers: api_headers(token: other_user.token)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as self and valid params' do
      it 'returns 200 OK and persists changes' do
        patch "/api/users/#{target_user.id}", params: update_params.to_json,
                                              headers: api_headers(token: target_user.token)
        expect(response).to have_http_status(:ok)
        expect(json_body['user']).to include(
          'first_name' => update_params[:user][:first_name],
          'last_name' => update_params[:user][:last_name]
        )
        target_user.reload
        expect(target_user.first_name).to eq(update_params[:user][:first_name])
        expect(target_user.last_name).to eq(update_params[:user][:last_name])
      end
    end

    context 'when authenticated as self and invalid params' do
      it 'returns 400 Bad Request and error keys' do
        patch "/api/users/#{target_user.id}", params: invalid_update_params.to_json,
                                              headers: api_headers(token: target_user.token)
        expect(response).to have_http_status(:bad_request)
        expect(json_body['errors']).to include('first_name', 'email')
      end
    end

    context 'when authenticated as self and new password is provided' do
      let(:password_params) do
        {
          user: {
            password: 'new_secure_password'
          }
        }
      end

      it 'returns 200 OK and changes the password' do
        patch "/api/users/#{target_user.id}", params: password_params.to_json,
                                              headers: api_headers(token: target_user.token)
        expect(response).to have_http_status(:ok)
        target_user.reload
        expect(target_user.authenticate('new_secure_password')).to be_truthy
      end
    end

    context 'when authenticated as self and new password is blank' do
      let(:password_params) do
        {
          user: {
            password: ''
          }
        }
      end

      it 'returns 400 Bad Request and error for password' do
        patch "/api/users/#{target_user.id}", params: password_params.to_json,
                                              headers: api_headers(token: target_user.token)
        expect(response).to have_http_status(:bad_request)
        expect(json_body['errors']).to include('password')
      end
    end

    context 'when authenticated as self and new password is nil' do
      let(:password_params) do
        {
          user: {
            password: nil
          }
        }
      end

      it 'returns 400 Bad Request and error for password' do
        patch "/api/users/#{target_user.id}", params: password_params.to_json,
                                              headers: api_headers(token: target_user.token)
        expect(response).to have_http_status(:bad_request)
        expect(json_body['errors']).to include('password')
      end
    end

    context 'when authenticated as self and trying to update role' do
      let(:role_params) do
        {
          user: {
            role: 'admin'
          }
        }
      end

      it 'does not allow role update' do
        patch "/api/users/#{target_user.id}", params: role_params.to_json,
                                              headers: api_headers(token: target_user.token)
        expect(response).to have_http_status(:ok)
        expect(json_body['user']['role']).to eq(target_user.role)
        target_user.reload
        expect(target_user.role).to be_nil
      end
    end

    context 'when authenticated as admin and valid params' do
      let!(:admin) { create(:user, role: :admin) }

      it 'updates any user' do
        patch "/api/users/#{target_user.id}", params: update_params.to_json,
                                              headers: api_headers(token: admin.token)
        expect(response).to have_http_status(:ok)
        expect(json_body['user']).to include(
          'first_name' => update_params[:user][:first_name],
          'last_name' => update_params[:user][:last_name]
        )
      end
    end

    context 'when authenticated as admin and invalid params' do
      let!(:admin) { create(:user, role: :admin) }

      it 'returns 400 Bad Request and error keys' do
        patch "/api/users/#{target_user.id}", params: invalid_update_params.to_json,
                                              headers: api_headers(token: admin.token)
        expect(response).to have_http_status(:bad_request)
        expect(json_body['errors']).to include('first_name', 'email')
      end
    end

    context 'when authenticated as admin and updating role' do
      let!(:admin) { create(:user, role: :admin) }
      let(:role_params) do
        {
          user: {
            role: 'admin'
          }
        }
      end

      it 'allows role update' do
        patch "/api/users/#{target_user.id}", params: role_params.to_json,
                                              headers: api_headers(token: admin.token)
        expect(response).to have_http_status(:ok)
        expect(json_body['user']['role']).to eq('admin')
      end
    end
  end

  describe 'DELETE /api/users/:id' do
    let!(:target_user) do
      create(:user, first_name: 'Example', last_name: 'User', email: 'example.user@example.com')
    end

    context 'when unauthenticated' do
      it 'returns 401 Unauthorized' do
        delete "/api/users/#{target_user.id}", headers: api_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated as other user' do
      let!(:other_user) { create(:user) }

      it 'returns 403 Forbidden' do
        delete "/api/users/#{target_user.id}", headers: api_headers(token: other_user.token)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when authenticated as self' do
      it 'returns 204 No Content and removes the user' do
        expect do
          delete "/api/users/#{target_user.id}", headers: api_headers(token: target_user.token)
        end.to change(User, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when authenticated as admin' do
      let!(:admin) { create(:user, role: :admin) }

      it 'returns 204 No Content and removes the user' do
        expect do
          delete "/api/users/#{target_user.id}", headers: api_headers(token: admin.token)
        end.to change(User, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
