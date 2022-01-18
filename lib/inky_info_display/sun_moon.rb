# frozen_string_literal: true

require 'sun_calc'

class InkyInfoDisplay
  class SunMoon
    MOON_PHASES = %w[
      new
      waxing-crescent-1 waxing-crescent-2 waxing-crescent-3
      waxing-crescent-4 waxing-crescent-5 waxing-crescent-6
      first-quarter
      waxing-gibbous-1 waxing-gibbous-2 waxing-gibbous-3
      waxing-gibbous-4 waxing-gibbous-5 waxing-gibbous-6
      full
      waning-gibbous-1 waning-gibbous-2 waning-gibbous-3
      waning-gibbous-4 waning-gibbous-5 waning-gibbous-6
      third-quarter
      waning-crescent-1 waning-crescent-2 waning-crescent-3
      waning-crescent-4 waning-crescent-5 waning-crescent-6
      new
    ].freeze

    attr_reader :now, :latitude, :longitude

    def initialize(now:, latitude:, longitude:)
      @now = now
      @latitude = latitude
      @longitude = longitude
    end

    def sun_times
      @sun_times ||= SunCalc.sun_times(now, latitude, longitude)
    end

    def sunrise
      sun_times[:sunrise]
    end

    def sunset
      sun_times[:sunset]
    end

    def moon_times
      @moon_times ||= SunCalc.moon_times(now, latitude, longitude)
    end

    def moonrise
      moon_times[:moonrise]
    end

    def moonset
      moon_times[:moonset]
    end

    # 0 is new moon, 14 is full moon
    def moon_phase
      (SunCalc.moon_illumination(moon_times[:lunar_noon] || now)[:phase] * 28).round
    end

    def moon_phase_icon
      MOON_PHASES[moon_phase]
    end
  end
end
