module Api
  class CompaniesController < ApplicationController
    before_action :set_company, only: [:show, :update, :destroy]

    def index
      companies = Company.all
      render json: CompanySerializer.render(companies, root: :companies), status: :ok
    end

    def show
      render json: CompanySerializer.render(company, root: :company), status: :ok
    end

    def create
      new_company = Company.new(company_params)
      if company.save
        render json: CompanySerializer.render(new_company, root: :company), status: :created
      else
        render_bad_request(company.errors.full_messages)
      end
    end

    def update
      if company.update(company_params)
        render json: CompanySerializer.render(company, root: :company), status: :ok
      else
        render_bad_request(company.errors.full_messages)
      end
    end

    def destroy
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
