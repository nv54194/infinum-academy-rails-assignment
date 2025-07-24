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

RSpec.describe Flight, type: :model do
  subject { build(:flight) }

  describe 'associations' do
    it { is_expected.to belong_to(:company) }
    it { is_expected.to have_many(:bookings).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:bookings) }
  end

  describe 'name validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:company_id).case_insensitive }
  end

  describe 'departs_at validations' do
    it { is_expected.to validate_presence_of(:departs_at) }
  end

  describe 'arrives_at validations' do
    it { is_expected.to validate_presence_of(:arrives_at) }
  end

  describe 'base_price validations' do
    it { is_expected.to validate_presence_of(:base_price) }
    it { is_expected.to validate_numericality_of(:base_price).is_greater_than(0) }
  end

  describe 'no_of_seats validations' do
    it { is_expected.to validate_presence_of(:no_of_seats) }
    it { is_expected.to validate_numericality_of(:no_of_seats).only_integer.is_greater_than(0) }
  end

  describe 'validation of departs_before_arrives' do
    let(:flight) { build(:flight, departs_at: departs_at, arrives_at: arrives_at) }

    context 'when departs_at is after arrives_at' do
      let(:departs_at) { 2.days.from_now }
      let(:arrives_at) { 1.day.from_now }

      it 'is not valid' do
        expect(flight).not_to be_valid
        expect(flight.errors[:departs_at]).to include('should be before arrives_at')
      end
    end

    context 'when departs_at is before arrives_at' do
      let(:departs_at) { 1.day.from_now }
      let(:arrives_at) { 2.days.from_now }

      it 'is valid' do
        expect(flight).to be_valid
      end
    end
  end
end
