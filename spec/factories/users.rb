# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  first_name      :string           not null
#  last_name       :string
#  email           :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  password_digest :string
#  token           :string
#
FactoryBot.define do
  factory :user do
    first_name { 'Test' }
    last_name  { 'User' }
    sequence(:email) { |n| "test#{n}@example.com" }
    password { 'password' }
  end
end
