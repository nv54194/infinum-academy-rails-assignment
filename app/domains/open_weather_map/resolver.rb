require 'json'

module OpenWeatherMap
  module Resolver
    PATH = File.expand_path('city.list.json', __dir__)

    def self.city_data
      @city_data ||= JSON.parse(File.read(PATH))
    end

    def self.city_id(city_name)
      city_data.find { |c| c.fetch('name').casecmp?(city_name) }&.fetch('id')
    end
  end
end
