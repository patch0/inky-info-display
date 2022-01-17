# frozen_string_literal: true

require 'inky_info_display/met_office_datapoint'
require 'inky_info_display/easy_tide'
require 'inky_info_display/open_weather_api'
require 'inky_info_display/wunderground'
require 'nokogiri'
require 'sun'

class InkyInfoDisplay
  WIND_DIRECTIONS = %w[N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW].freeze

  attr_reader :svg, :now

  def initialize(template:)
    @template = template
    @svg = File.open(template) { |f| Nokogiri::XML(f) }
    @now = Time.now
  end

  def met_office_datapoint
    @met_office_datapoint ||= MetOfficeDatapoint.new(api_key: ENV['DATAPOINT_API_KEY'], location_id: ENV['DATAPOINT_LOCATION_ID'])
  end

  alias forecast met_office_datapoint

  def easy_tide
    @easy_tide ||= EasyTide.new(station_id: ENV['EASYTIDE_PORT_ID'])
  end

  alias tides easy_tide

  def openweather
    @openweather ||= OpenWeatherApi.new(city_id: ENV['OPENWEATHER_CITY_ID'], api_key: ENV['OPENWEATHER_API_KEY'])
  end

  def wunderground
    @wunderground ||= Wunderground.new(station_id: ENV['WUNDERGROUND_STATION_ID'], api_key: ENV['WUNDERGROUND_API_KEY'])
  end

  alias current_conditions wunderground

  def latitude
    Float(ENV['LATITUDE'])
  end

  def longitude
    Float(ENV['LONGITUDE'])
  end

  def root_path
    @root_path ||= File.dirname(@template)
  end

  def update
    set_text(id: 'day', content: now.strftime('%A'))
    set_text(id: 'date', content: now.strftime('%d %B'))
    set_text(id: 'last_update', content: now.strftime('Updated at %H:%M'))
    set_text(id: 'sunrise', content: sunrise.localtime.strftime('%H:%M'))
    set_text(id: 'sunset', content: sunset.localtime.strftime('%H:%M'))

    update_forecast
    update_current_conditions
    update_tide
  end

  def update_forecast
    forecast.interval_forecasts.each_with_index do |f, i|
      set_text(id: "time_#{i}", content: f.time.localtime.strftime('%l%P'))
      set_text(id: "temp_#{i}", content: "#{f.temp}°")
      set_text(id: "pp_#{i}", content: "#{f.precip_prob}%")
      set_text(id: "wind_#{i}", content: f.wind_speed.round)
      set_weather_icon(id: "weather_icon_#{i}", icon: f.weather_icon)
      set_wind_dir(id: "wind_dir_#{i}", direction: f.wind_dir)
    end
  end

  def update_tide
    set_text(id: 'tide_time', content: tides.next_high_tide.time.localtime.strftime('%H:%M'))
    set_text(id: 'tide_height', content: format('%.1fm', tides.next_high_tide.height))
  end

  def update_current_conditions
    set_text(id: 'temp_outside', content: "#{current_conditions.current_temp.round}°")
    set_text(id: 'wind', content: "#{current_conditions.current_wind_speed.round} km/h")
    set_wind_dir(id: 'wind_dir', degrees: current_conditions.current_wind_dir)
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

    element['xlink:href'] = path || "#{root_path}/weather-icons/wi-#{icon}.svg"
  end

  def set_wind_dir(id: nil, direction: nil, degrees: nil, selector: nil)
    selector ||= "image##{id}"
    element = svg.css(selector).first
    return unless element

    degrees ||= 22.5 * (WIND_DIRECTIONS.index(direction.upcase) || 0)
    return if degrees.zero?

    x_centre = Float(element['x']) + Float(element['width']) / 2.0
    y_centre = Float(element['y']) + Float(element['height']) / 2.0

    element['transform'] = "rotate(#{degrees},#{x_centre},#{y_centre})"
  end

  def sunrise
    @sunrise ||= Sun.sunrise(now, latitude, longitude)
  end

  def sunset
    @sunset ||= Sun.sunset(now, latitude, longitude)
  end

  def to_s
    svg.to_s
  end
end
