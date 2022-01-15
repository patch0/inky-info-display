require 'httparty'

class EasyTide
  include HTTParty

  base_uri 'https://easytide.admiralty.co.uk'

  attr_reader :station_id

  def initialize(station_id:)
    @station_id = station_id
  end

  def predictions
    @predictions ||= self.class.get('/Home/GetPredictionData', query: { stationId: station_id })
  end

  def tidal_event_list
    @tidal_event_list ||= predictions['tidalEventList'].map { |te| TidalEvent.new(te) }
  end

  def next_high_tide
    tidal_event_list.sort { |a, b| a.time <=> b.time }.find { |t| t.time > Time.now && t.high_tide? }
  end

  def next_low_tide
    tidal_event_list.sort { |a, b| a.time <=> b.time }.find { |t| t.time > Time.now && t.low_tide? }
  end

  class TidalEvent
    attr_reader :event_type, :time, :height

    def initialize(data)
      @event_type = Integer(data['eventType'])
      @time = Time.parse(data['dateTime'])
      @height = Float(data['height'])
    end

    def high_tide?
      event_type.zero?
    end

    def low_tide?
      !high_tide?
    end
  end
end
