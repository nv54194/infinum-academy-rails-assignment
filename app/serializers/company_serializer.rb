# == Schema Information
#
# Table name: companies
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class CompanySerializer < Blueprinter::Base
  identifier :id

  fields :name, :created_at, :updated_at

  field :no_of_active_flights do |company, _|
    company.flights.active.count
  end
end
