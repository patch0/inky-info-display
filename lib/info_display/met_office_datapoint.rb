# frozen_string_literal: true

require 'httparty'
require 'time'

class MetOfficeDatapoint
  include HTTParty
  base_uri 'http://datapoint.metoffice.gov.uk'

  WEATHER_ICON_MAP = {
    'NA' => 'na',
    '0' => 'night-clear',
    '1' => 'day-sunny',
    '2' => 'night-alt-cloudy',
    '3' => 'day-cloudy',
    '5' => 'day-fog',
    '6' => 'fog',
    '7' => 'cloud',
    '8' => 'cloudy',
    '9' => 'night-alt-showers',
    '10' => 'day-showers',
    '11' => 'rain-mix',
    '12' => 'showers',
    '13' => 'night-alt-rain',
    '14' => 'day-rain',
    '15' => 'rain',
    '16' => 'night-alt-sleet',
    '17' => 'day-sleet',
    '18' => 'sleet',
    '19' => 'night-alt-hail',
    '20' => 'day-hail',
    '21' => 'hail',
    '22' => 'night-alt-snow',
    '23' => 'day-snow',
    '24' => 'snow',
    '25' => 'night-alt-snow',
    '26' => 'day-snow',
    '27' => 'snow',
    '28' => 'night-alt-storm-showers',
    '29' => 'day-storm-showers',
    '30' => 'thunderstorm'
  }.freeze

  # See https://www.metoffice.gov.uk/services/data/datapoint/code-definitions
  WEATHER_CODES = {
    'NA' => 'Not available',
    '0' => 'Clear night',
    '1' => 'Sunny day',
    '2' => 'Partly cloudy (night)',
    '3' => 'Partly cloudy (day)',
    '4' => 'Not used',
    '5' => 'Mist',
    '6' => 'Fog',
    '7' => 'Cloudy',
    '8' => 'Overcast',
    '9' => 'Light rain shower (night)',
    '10' => 'Light rain shower (day)',
    '11' => 'Drizzle',
    '12' => 'Light rain',
    '13' => 'Heavy rain shower (night)',
    '14' => 'Heavy rain shower (day)',
    '15' => 'Heavy rain',
    '16' => 'Sleet shower (night)',
    '17' => 'Sleet shower (day)',
    '18' => 'Sleet',
    '19' => 'Hail shower (night)',
    '20' => 'Hail shower (day)',
    '21' => 'Hail',
    '22' => 'Light snow shower (night)',
    '23' => 'Light snow shower (day)',
    '24' => 'Light snow',
    '25' => 'Heavy snow shower (night)',
    '26' => 'Heavy snow shower (day)',
    '27' => 'Heavy snow',
    '28' => 'Thunder shower (night)',
    '29' => 'Thunder shower (day)',
    '30' => 'Thunder'
  }.freeze

  VISIBILITY_CODES = {
    'UN' => 'Unknown',
    'VP' => 'Very poor - Less than 1 km',
    'PO' => 'Poor - Between 1-4 km',
    'MO' => 'Moderate - Between 4-10 km',
    'GO' => 'Good - Between 10-20 km',
    'VG' => 'Very good - Between 20-40 km',
    'EX' => 'Excellent - More than 40 km'
  }.freeze

  def initialize(api_key:, location_id:)
    @query = { key: api_key }
    @uri = "/public/data/val/wxfcs/all/json/#{location_id}"
  end

  def daily
    @daily ||= Forecast.new(self.class.get(@uri, { query: @query.merge(res: :daily) }))
  end

  def three_hourly
    @three_hourly ||= Forecast.new(self.class.get(@uri, { query: @query.merge(res: '3hourly') }))
  end

  class Forecast
    attr_reader :data

    def initialize(data)
      @data = data
    end

    def site_rep
      data['SiteRep']
    end

    def dv
      site_rep['DV']
    end

    def location
      dv['Location']
    end

    def period
      location['Period']
    end

    def forecasts
      @forecasts ||= period.map do |period|
        next if period['Rep'].empty?

        date = Time.parse(period['value'])
        period['Rep'].map.with_index do |rep, _index|
          rep['time'] = date + Integer(rep['$']) * 60

          rep
        end
      end.flatten
    end

    def issued_at
      Time.parse(dv['dataDate'])
    end

    def future_forecasts
      forecasts.select { |f| f['time'] >= issued_at }
    end
  end
end
