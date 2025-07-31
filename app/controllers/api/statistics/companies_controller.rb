module Api
  module Statistics
    class CompaniesController < ApplicationController
      def index
        authorize [:statistics, :company]
        companies = ::Statistics::CompaniesQuery.new(relation: Company.all).with_stats
        render json: ::Statistics::CompanySerializer.render(companies, root: :companies)
      end
    end
  end
end
