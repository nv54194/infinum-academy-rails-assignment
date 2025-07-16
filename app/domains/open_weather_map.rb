require 'httparty'
require_relative 'open_weather_map/resolver'

module OpenWeatherMap
  API_URL = 'https://api.openweathermap.org/data/2.5'

  def self.city(city_name)
    city_id = Resolver.city_id(city_name)
    return nil unless city_id

    fetch(:weather, id: city_id)
  end

  def self.fetch(endpoint, params)
    query = params.merge(appid: api_key)
    response = HTTParty.get("#{API_URL}/#{endpoint}", query: query)
    raise "Error fetching data from OpenWeatherMap: #{response.code}" unless response.success?

    City.parse(response.parsed_response)
  end

  def self.api_key
    Rails.application.credentials.open_weather_map_api_key
  end

  private_class_method :fetch, :api_key
end
