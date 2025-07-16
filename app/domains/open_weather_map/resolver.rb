require 'json'

module OpenWeatherMap
  module Resolver
    PATH = File.expand_path('city_ids.json', __dir__)

    def self.city_data
      @city_data ||= JSON.parse(File.read(PATH))
    end

    def self.city_id(city_name)
      city_data.find { |c| c['name'].casecmp?(city_name) }&.fetch('id')
    end
  end
end
