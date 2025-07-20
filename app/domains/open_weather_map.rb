require 'httparty'

module OpenWeatherMap
  API_URL = 'https://api.openweathermap.org/data/2.5'
  API_KEY = Rails.application.credentials.open_weather_map_api_key

  def self.city(city_name)
    city_id = Resolver.city_id(city_name)
    return nil unless city_id

    fetch(:weather, id: city_id)
  end

  def self.fetch(endpoint, params)
    query = params.merge(appid: API_KEY)
    response = HTTParty.get("#{API_URL}/#{endpoint}", query: query)
    raise "Error fetching data from OpenWeatherMap: #{response.code}" unless response.success?

    City.parse(response.parsed_response)
  end

  private_class_method :fetch
end
