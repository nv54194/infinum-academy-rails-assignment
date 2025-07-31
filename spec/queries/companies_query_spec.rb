require 'rails_helper'

RSpec.describe CompaniesQuery do
  describe '#result' do
    it 'returns companies sorted by name ASC by default' do
      create(:company, name: 'A')
      create(:company, name: 'B')
      create(:company, name: 'C')
      result = described_class.new.result
      expect(result.map(&:name)).to eq(%w[A B C])
    end

    it 'returns only companies with active flights when filter=active' do
      company_a = create(:company, name: 'A')
      company_b = create(:company, name: 'B')
      create(:flight, company: company_a, departs_at: 2.hours.from_now,
                      arrives_at: 4.hours.from_now)
      create(:flight, company: company_b, departs_at: 2.hours.ago, arrives_at: 1.hour.ago)
      result = described_class.new(params: { filter: 'active' }).result
      expect(result).to contain_exactly(company_a)
    end
  end
end
