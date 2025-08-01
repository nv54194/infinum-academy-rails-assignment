module Statistics
  class CompanySerializer < Blueprinter::Base
    field :company_id
    field :total_revenue
    field :total_no_of_booked_seats
    field :average_price_of_seats do |company, _|
      company[:average_price_of_seats].to_f
    end
  end
end
