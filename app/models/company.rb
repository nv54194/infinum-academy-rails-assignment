# == Schema Information
#
# Table name: companies
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Company < ApplicationRecord
  has_many :flights, dependent: :destroy

  validates :name,
            presence: true,
            uniqueness: { case_sensitive: false }
end
