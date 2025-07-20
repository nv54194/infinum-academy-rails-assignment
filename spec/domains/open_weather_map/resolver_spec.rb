RSpec.describe OpenWeatherMap::Resolver do
  describe '.city_id' do
    it 'returns the correct id for a known city name' do
      expect(described_class.city_id('Zagreb')).to eq(3_186_886)
    end

    it 'returns nil for an unknown city name' do
      expect(described_class.city_id('Zabreg')).to be_nil
    end
  end
end
