# frozen_string_literal: true

require 'httparty'
require 'time'

class InkyInfoDisplay
  class MetOfficeDatapoint
    include HTTParty
    base_uri 'http://datapoint.metoffice.gov.uk'

    # See https://www.metoffice.gov.uk/services/data/datapoint/code-definitions
    WEATHER_ICON_MAP = {
      'NA' => 'na',
      '0' => 'night-clear',
      '1' => 'day-sunny',
      '2' => 'night-alt-cloudy',
      '3' => 'day-cloudy',
      '5' => 'fog',
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
      @now = Time.now
    end

    def daily
      @daily ||= Forecast.new(self.class.get(@uri, { query: @query.merge(res: :daily) }))
    end

    def three_hourly
      @three_hourly ||= Forecast.new(self.class.get(@uri, { query: @query.merge(res: '3hourly') }))
    end

    def three_hourly_forecasts
      @three_hourly_forecasts ||= three_hourly.forecasts.select { |f| f.time >= @now }
    end

    alias interval_forecasts three_hourly_forecasts

    def daily_forecasts
      @daily_forecasts ||= daily.forecasts.select { |f| f.time >= @now }
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

      def reports
        @reports ||= period.map do |period|
          next if period['Rep'].empty?

          date = Time.parse(period['value'])
          period['Rep'].map { |r| Report.new(data: r, date: date) }
        end.flatten
      end

      alias forecasts reports

      def issued_at
        Time.parse(dv['dataDate'])
      end
    end

    class Report
      attr_reader :data, :date

      def initialize(data:, date:)
        @data = data
        @date = date
      end

      def time
        @time ||= date + offset
      end

      def offset
        @offset ||= case data['$']
                    when 'Day'
                      720
                    when 'Night'
                      1440
                    else
                      Integer(data['$']) * 60
                    end
      end

      def precip_prob
        Integer(data['Pp'])
      end

      def temp
        Integer(data['T'])
      end

      def weather_icon
        MetOfficeDatapoint::WEATHER_ICON_MAP[data['W']]
      end

      def wind_dir
        data['D']
      end

      def wind_speed
        Integer(data['S']) / 1.609344
      end
    end
  end
end
