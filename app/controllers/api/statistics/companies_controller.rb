module Api
  module Statistics
    class CompaniesController < ApplicationController
      before_action :authorize_admin!

      def index
        companies = ::Statistics::CompaniesQuery.new(relation: Company.all).with_stats
        render json: ::Statistics::CompanySerializer.render(companies, root: :companies)
      end

      private

      def authorize_admin!
        head :forbidden unless current_user&.admin?
      end
    end
  end
end
