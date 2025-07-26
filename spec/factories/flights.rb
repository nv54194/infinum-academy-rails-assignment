# == Schema Information
#
# Table name: flights
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  no_of_seats :integer
#  base_price  :integer          not null
#  departs_at  :datetime         not null
#  arrives_at  :datetime         not null
#  company_id  :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do
  factory :flight do
    sequence(:name) { |n| "Flight #{n}" }
    no_of_seats { 100 }
    base_price  { 200 }
    departs_at  { 2.days.from_now }
    arrives_at  { 3.days.from_now }
    association :company
  end
end
