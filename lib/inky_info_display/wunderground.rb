require 'httparty'

class InkyInfoDisplay
  class Wunderground
    include HTTParty

    base_uri 'https://api.weather.com'

    attr_reader :station_id, :api_key

    def initialize(station_id:, api_key:)
      @station_id = station_id
      @api_key = api_key
    end

    def current
      @current ||= self.class.get('/v2/pws/observations/current',
                                  query: { apiKey: api_key,
                                           stationId: station_id,
                                           units: :m,
                                           format: :json })
    end

    def observation
      current['observations'].first
    end

    def current_temp
      observation.dig('metric', 'temp')
    end

    def current_wind_speed
      observation.dig('metric', 'windSpeed')
    end

    def current_wind_dir
      observation['winddir']
    end

    def current_precip_rate
      observation.dig('metric', 'precipRate')
    end

    def current_humidity
      observation['humidity']
    end
  end
end
