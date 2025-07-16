module OpenWeatherMap
  class City
    include Comparable

    attr_reader :id, :lat, :lon, :name, :temp_k

    def initialize(id:, lat:, lon:, name:, temp_k:)
      @id = id
      @lat = lat
      @lon = lon
      @name = name
      @temp_k = temp_k
    end

    def temp
      (temp_k - 273.15).round(2)
    end

    def <=>(other)
      [temp_k, name] <=> [other.temp_k, other.name]
    end
  end
end
