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
#  role            :string
#
class UserSerializer < Blueprinter::Base
  identifier :id

  fields :first_name,
         :last_name,
         :email,
         :role,
         :created_at,
         :updated_at
end
