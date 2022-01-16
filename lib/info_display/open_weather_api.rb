require 'httparty'

class OpenWeatherApi
  include HTTParty

  base_uri 'https://api.openweathermap.org'

  attr_reader :city_id, :api_key

  def initialize(city_id:, api_key:)
    @city_id = city_id
    @api_key = api_key
  end

  def current
    @current ||= self.class.get('/data/2.5/weather', query: { appid: api_key, id: city_id, units: :metric })
  end

  def sunrise
    Time.at current.dig('sys', 'sunrise')
  end

  def sunset
    Time.at current.dig('sys', 'sunset')
  end

  def current_temp
    current.dig('main', 'temp')
  end

  def current_wind_speed
    current.dig('wind', 'speed') * 3600 / 1607
  end

  def current_wind_dir
    current.dig('wind', 'deg')
  end
end
