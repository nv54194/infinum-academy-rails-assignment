module Api
  class CompaniesController < ApplicationController
    before_action :set_company, only: [:show, :update, :destroy]
    skip_before_action :authenticate_user, only: [:index, :show]

    def index
      render json: serialize(Company.all, root: :companies)
    end

    def show
      render json: serialize(company, root: :company)
    end

    def create
      authorize Company
      new_company = Company.new(company_params)
      if new_company.save
        render json: CompanySerializer.render(new_company, root: :company), status: :created
      else
        render_bad_request(new_company.errors.messages)
      end
    end

    def update
      authorize company
      if company.update(company_params)
        render json: CompanySerializer.render(company, root: :company), status: :ok
      else
        render_bad_request(company.errors.messages)
      end
    end

    def destroy
      authorize company
      company.destroy
      head :no_content
    end

    private

    def set_company
      render_not_found unless company
    end

    def company
      @company ||= Company.find_by(id: params[:id])
    end

    def company_params
      params.require(:company).permit(:name)
    end
  end
end
