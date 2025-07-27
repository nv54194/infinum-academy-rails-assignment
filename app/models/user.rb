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
class User < ApplicationRecord
  has_secure_password
  has_secure_token

  has_many :bookings, dependent: :destroy
  has_many :flights, through: :bookings

  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/ }

  validates :first_name,
            presence: true,
            length: { minimum: 2 }

  def admin?
    role == 'admin'
  end

  def password=(unencrypted_password)
    @password_was_blank = !unencrypted_password.nil? && unencrypted_password.empty?
    super
  end

  validate :password_not_blank, on: :update

  def password_not_blank
    return unless @password_was_blank

    errors.add(:password, "can't be blank")
  end
end
