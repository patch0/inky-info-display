# frozen_string_literal: true

require 'info_display/met_office_datapoint'
require 'info_display/easy_tide'
require 'nokogiri'

class InfoDisplay
  attr_reader :svg, :datapoint, :easy_tide

  def initialize(template:)
    @datapoint = MetOfficeDatapoint.new(api_key: ENV['DATAPOINT_API_KEY'], location_id: ENV['DATAPOINT_LOCATION_ID'])
    @easy_tide = EasyTide.new(station_id: ENV['EASYTIDE_PORT_ID'])
    @template = template
    @svg = File.open(template) { |f| Nokogiri::XML(f) }
  end

  def root_path
    @root_path ||= File.dirname(@template)
  end

  def update
    svg.at_css('text#day tspan').content = datapoint.three_hourly.issued_at.strftime('%A')
    svg.at_css('text#date tspan').content = datapoint.three_hourly.issued_at.strftime('%d %B')
    svg.at_css('text#issued_at tspan').content = "Forecast issued at #{datapoint.three_hourly.issued_at.strftime('%l:%M %P')}"

    (0..3).each do |i|
      svg.at_css("text#time_#{i} tspan").content = datapoint.three_hourly.future_forecasts[i]['time'].strftime('%l%P')
      svg.at_css("text#temp_#{i} tspan").content = "#{datapoint.three_hourly.future_forecasts[i]['T']}°"
      svg.at_css("text#pp_#{i} tspan").content = "#{datapoint.three_hourly.future_forecasts[i]['Pp']}%"
      svg.at_css("text#wind_#{i} tspan").content = datapoint.three_hourly.future_forecasts[i]['S']
      svg.at_css("image#weather_icon_#{i}")['xlink:href'] =
        "#{root_path}/weather-icons/wi-#{MetOfficeDatapoint::WEATHER_ICON_MAP[datapoint.three_hourly.future_forecasts[i]['W']]}.svg"
    end

    svg.at_css('text#tide_time tspan').content = easy_tide.next_high_tide.time.strftime('%H:%M')
    svg.at_css('text#tide_height tspan').content = format('%.2f', easy_tide.next_high_tide.height)
  end

  def to_s
    svg.to_s
  end
end
