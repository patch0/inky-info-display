# frozen_string_literal: true

require 'info_display/met_office_datapoint'
require 'info_display/easy_tide'
require 'info_display/open_weather_api'
require 'nokogiri'

class InfoDisplay
  attr_reader :svg, :now

  def initialize(template:)
    @template = template
    @svg = File.open(template) { |f| Nokogiri::XML(f) }
    @now = Time.now
  end

  def met_office
    @met_office ||= MetOfficeDatapoint.new(api_key: ENV['DATAPOINT_API_KEY'], location_id: ENV['DATAPOINT_LOCATION_ID'])
  end

  def tides
    @tides ||= EasyTide.new(station_id: ENV['EASYTIDE_PORT_ID'])
  end

  def openweather
    @openweather ||= OpenWeatherApi.new(city_id: ENV['OPENWEATHER_CITY_ID'], api_key: ENV['OPENWEATHER_API_KEY'])
  end

  def root_path
    @root_path ||= File.dirname(@template)
  end

  def icon_path_for(icon:)
    "#{root_path}/weather-icons/wi-#{MetOfficeDatapoint::WEATHER_ICON_MAP[icon]}.svg"
  end

  def update
    set_text(id: 'day', content: now.strftime('%A'))
    set_text(id: 'date', content: now.strftime('%d %B'))
    set_text(id: 'last_update', content: now.strftime('Updated at %Y-%m-%d %H:%M'))
    update_forecast
    update_current_conditions
    update_tide
  end

  def update_forecast
    met_office.three_hourly.future_forecasts.each_with_index do |forecast, i|
      set_text(id: "time_#{i}", content: forecast['time'].localtime.strftime('%l%P'))
      set_text(id: "temp_#{i}", content: "#{forecast['T']}°")
      set_text(id: "pp_#{i}", content: "#{forecast['Pp']}%")
      set_text(id: "wind_#{i}", content: forecast['S'])
      set_weather_icon(id: "weather_icon_#{i}", icon: forecast['W'])
    end
    set_text(id: 'issued_at',
             content: "Forecast issued at #{met_office.three_hourly.issued_at}")
  end

  def update_tide
    set_text(id: 'tide_time', content: tides.next_high_tide.time.localtime.strftime('%H:%M'))
    set_text(id: 'tide_height', content: format('%.1fm', tides.next_high_tide.height))
  end

  def update_current_conditions
    set_text(id: 'sunrise', content: openweather.sunrise.localtime.strftime('%H:%M'))
    set_text(id: 'sunset', content: openweather.sunset.localtime.strftime('%H:%M'))
    set_text(id: 'temp_outside', content: "#{openweather.current_temp.round}°")
    set_text(id: 'wind', content: "#{openweather.current_wind_speed.round} mph")
    set_text(id: 'temp_inside', content: '--')
  end

  def set_text(id: nil, content: nil, selector: nil)
    selector ||= "text##{id} tspan"
    element = svg.css(selector).first
    return unless element

    element.content = content
  end

  def set_weather_icon(id: nil, icon: nil, path: nil, selector: nil)
    selector ||= "image##{id}"
    element = svg.css(selector).first
    return unless element

    element['xlink:href'] = path || icon_path_for(icon: icon)
  end

  def to_s
    svg.to_s
  end
end
