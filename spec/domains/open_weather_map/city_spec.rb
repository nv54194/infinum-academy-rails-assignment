RSpec.describe OpenWeatherMap::City do
  let(:city) do
    described_class.new(id: 3_186_886, lat: 45.8, lon: 15.9, name: 'Zagreb', temp_k: 298.15)
  end

  describe 'attribute readers' do
    it 'returns the correct id' do
      expect(city.id).to eq(3_186_886)
    end

    it 'returns the correct lat' do
      expect(city.lat).to eq(45.8)
    end

    it 'returns the correct lon' do
      expect(city.lon).to eq(15.9)
    end

    it 'returns the correct name' do
      expect(city.name).to eq('Zagreb')
    end

    it 'returns the correct temp_k' do
      expect(city.temp_k).to eq(298.15)
    end
  end

  describe '#temp' do
    it 'converts temperature correctly' do
      expect(city.temp).to eq(25.0)
    end
  end

  describe '#<=>' do
    let(:warmer_city) do
      described_class.new(id: 1, lat: 0, lon: 0, name: 'Dubrovnik', temp_k: 300.15)
    end
    let(:cooler_city) do
      described_class.new(id: 2, lat: 0, lon: 0, name: 'Moskva', temp_k: 285.15)
    end
    let(:same_temp_first_name) do
      described_class.new(id: 3, lat: 0, lon: 0, name: 'Antwerpen', temp_k: 298.15)
    end
    let(:same_temp_second_name) do
      described_class.new(id: 4, lat: 0, lon: 0, name: 'Zlatibor', temp_k: 298.15)
    end

    it 'receiver has lower temperature than other' do
      expect(cooler_city <=> warmer_city).to eq(-1)
    end

    it 'receiver has same temperature as other but name comes first alphabetically' do
      expect(same_temp_first_name <=> same_temp_second_name).to eq(-1)
    end

    it 'receiver has same temperature and name as other' do
      expect(cooler_city <=> cooler_city).to eq(0) # rubocop:disable Lint/BinaryOperatorWithIdenticalOperands
    end

    it 'receiver has higher temperature than other' do
      expect(warmer_city <=> cooler_city).to eq(1)
    end

    it 'receiver has same temperature as other but its name comes second alphabetically' do
      expect(same_temp_second_name <=> same_temp_first_name).to eq(1)
    end
  end
end
