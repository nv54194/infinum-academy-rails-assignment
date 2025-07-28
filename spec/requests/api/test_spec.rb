RSpec.describe 'Users API', type: :request do
  let!(:admin) { create(:user, role: 'admin') }
  let(:headers) { { 'Authorization' => admin.token } }

  it 'admin can set role when creating user' do
    params = {
      user: {
        first_name: 'Clark',
        last_name: 'Zulauf',
        email: 'clark@example.com',
        password: 'password',
        role: 'admin'
      }
    }

    post '/api/users', params: params, headers: headers

    user = User.find_by(email: 'clark@example.com')
    expect(user.admin?).to be true
  end
end
