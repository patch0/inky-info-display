# frozen_string_literal: true

require 'inky_info_display/met_office_datapoint'
require 'inky_info_display/easy_tide'
require 'inky_info_display/influx_db'
require 'inky_info_display/sun_moon'
require 'nokogiri'

class InkyInfoDisplay
  WIND_DIRECTIONS = %w[N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW].freeze

  attr_reader :svg, :now

  def initialize(template:)
    @template = template
    @svg = File.open(template) { |f| Nokogiri::XML(f) }
    @now = Time.now
  end

  def met_office_datapoint
    @met_office_datapoint ||= MetOfficeDatapoint.new(api_key: ENV['DATAPOINT_API_KEY'],
                                                     location_id: ENV['DATAPOINT_LOCATION_ID'])
  end

  alias forecast met_office_datapoint

  def easy_tide
    @easy_tide ||= EasyTide.new(station_id: ENV['EASYTIDE_PORT_ID'])
  end

  alias tides easy_tide

  def wunderground
    @wunderground ||= Wunderground.new(station_id: ENV['WUNDERGROUND_STATION_ID'], api_key: ENV['WUNDERGROUND_API_KEY'])
  end

  def influx_db
    @influx_db||= InfluxDb.new
  end

  alias current_conditions influx_db

  def sun_moon
    SunMoon.new(now: now, latitude: Float(ENV['LATITUDE']), longitude: Float(ENV['LONGITUDE']))
  end

  def root_path
    @root_path ||= File.dirname(@template)
  end

  def update
    set_text(selector: 'tspan#day', content: now.strftime('%A'))
    set_text(selector: 'tspan#date', content: now.strftime('%d %B'))
    set_text(id: 'last_update', content: now.strftime('Updated at %H:%M'))

    update_forecast
    update_current_conditions
    update_sun_moon
    update_tide
  end

  def update_sun_moon
    set_text(id: 'sunrise', content: sun_moon.sunrise.localtime.strftime('%H:%M'))
    set_text(id: 'sunset', content: sun_moon.sunset.localtime.strftime('%H:%M'))
    set_text(id: 'moonrise', content: sun_moon.moonrise&.localtime&.strftime('%H:%M') || '--')
    set_text(id: 'moonset', content: sun_moon.moonset&.localtime&.strftime('%H:%M' || '--'))
    set_weather_icon(id: 'moon_phase_icon', icon: "moon-alt-#{sun_moon.moon_phase_icon}")
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
    set_text(id: 'temp_inside', content: "#{current_conditions.current_temp_inside&.round}°")
    set_text(id: 'temp_outside', content: "#{current_conditions.current_temp_outside&.round}°")
    set_text(id: 'wind', content: "#{current_conditions.current_wind_speed&.round} km/h")
    set_wind_dir(id: 'wind_dir', degrees: 180 + current_conditions.current_wind_dir)
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

    degrees ||= 22.5 * (WIND_DIRECTIONS.index(direction&.upcase) || 0)
    return if degrees.zero?

    x_centre = Float(element['x']) + Float(element['width']) / 2.0
    y_centre = Float(element['y']) + Float(element['height']) / 2.0

    element['transform'] = "rotate(#{degrees},#{x_centre},#{y_centre})"
  end

  def to_s
    svg.to_s
  end
end
