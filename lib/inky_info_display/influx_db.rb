# frozen_string_literal: true

require 'httparty'

class InkyInfoDisplay
  class InfluxDb
    include HTTParty

    base_uri ENV.fetch('INFLUX_DB_URL')

    DB = ENV.fetch('INFLUX_DB_DB')

    QUERY = 'SELECT "%<field>s" FROM "%<measurement>s" ' \
            'WHERE time >= now() - 30m ' \
            'GROUP BY "location" ' \
            'ORDER BY time DESC LIMIT 1'

    MEASUREMENTS = {
      temperature: %w(temperature_c temperature),
      wind_speed: %w(wind_speed_kmh wind_speed),
      wind_direction: %w(wind_direction wind_direction)
    }

    attr_reader :station_id, :api_key

    def self.query(field:, measurement:)
      q = Kernel.format(QUERY, field: field, measurement: measurement)
      data = get('/query', query: { db: DB, q: q })
      data['results'].first['series']
    end

    def self.find_by_tag(data:, tag:, value:)
      data.find { |d| d.dig('tags', tag) == value }&.dig('values', -1, -1)
    end

    def current_temperatures
      @current_temperatures ||= self.class.query(field: :temperature_c,
                                                 measurement: :temperature)
    end

    def current_temp_outside
      self.class.find_by_tag(data: current_temperatures,
                             tag: 'location',
                             value: 'outside')
    end

    def current_temp_inside
      self.class.find_by_tag(data: current_temperatures,
                             tag: 'location',
                             value: 'kitchen')
    end

    def current_wind_speeds
      @current_wind_speeds ||= self.class.query(field: :wind_speed_kmh,
                                                measurement: :wind_speed)
    end

    def current_wind_speed
      self.class.find_by_tag(data: current_wind_speeds,
                             tag: 'location',
                             value: 'outside')
    end

    def current_wind_directions
      @current_wind_directions ||= self.class.query(field: :wind_direction,
                                                    measurement: :wind_direction)
    end

    def current_wind_dir
      self.class.find_by_tag(data: current_wind_directions,
                             tag: 'location',
                             value: 'outside')
    end
  end
end
