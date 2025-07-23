require 'rails_helper'

RSpec.describe Company, type: :model do
  subject { build(:company) }

  describe 'associations' do
    it { is_expected.to have_many(:flights).dependent(:destroy) }
  end

  describe 'name validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end
end
