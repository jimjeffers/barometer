module Barometer
  class WeatherService::Yahoo < WeatherService

    #########################################################################
    # PRIVATE
    # If class methods could be private, the remaining methods would be.
    #

    def self._source_name; :yahoo; end
    def self._accepted_formats; [:zipcode, :weather_id, :woe_id]; end

    def self._wet_icon_codes
      codes = [1] + (3..18).to_a + [35] + (37..43).to_a + (45..47).to_a
      codes.collect {|c| c.to_s}
    end
    def self._sunny_icon_codes
      codes = (29..34).to_a + [36]
      codes.collect {|c| c.to_s}
    end

   def self._build_extra(measurement, result, metric=true)
     #raise ArgumentError unless measurement.is_a?(Data::Measurement)
     #raise ArgumentError unless query.is_a?(Barometer::Query)

     # use todays sun data for all future days
     if measurement.forecast && measurement.current.sun
       measurement.forecast.each do |forecast|
         forecast.sun = measurement.current.sun
       end
     end
     measurement
   end

    def self._build_timezone(data)
      if data && data['item'] && data['item']['pubDate']
        zone_match = data['item']['pubDate'].match(/ ([A-Z]*)$/)
        Data::Zone.new(zone_match[1]) if zone_match
      end
    end

    def self._build_links(data)
      links = {}
      if data["title"] && data["link"]
        links[data["title"]] = data["link"]
      end
      links
    end

    def self._build_current(data, metric=true)
      raise ArgumentError unless data.is_a?(Hash)
      current = Measurement::Result.new(metric)
      if data
        if data['item'] && data['item']['condition']
          condition_result = data['item']['condition']
          current.updated_at = Data::LocalDateTime.parse(condition_result['date'])
          current.icon = condition_result['code']
          current.condition = condition_result['text']
          current.temperature = Data::Temperature.new(metric)
          current.temperature << condition_result['temp']
        end
        if data['atmosphere']
          atmosphere_result = data['atmosphere']
          current.humidity = atmosphere_result['humidity'].to_i
          current.pressure = Data::Pressure.new(metric)
          current.pressure << atmosphere_result['pressure']
          current.visibility = Data::Distance.new(metric)
          current.visibility << atmosphere_result['visibility']
        end
        if data['wind']
          wind_result = data['wind']
          current.wind = Data::Speed.new(metric)
          current.wind << wind_result['speed']
          current.wind.degrees = wind_result['degrees'].to_f
          current.wind_chill = Data::Temperature.new(metric)
          current.wind_chill << wind_result['chill']
        end
      end
      current
    end

    def self._build_forecast(data, metric=true)
      raise ArgumentError unless data.is_a?(Hash)
      forecasts = Measurement::ResultArray.new

      if data && data['item'] && data['item']['forecast']
         forecast_result = data['item']['forecast']

        forecast_result.each do |forecast|
          forecast_measurement = Measurement::Result.new
          forecast_measurement.icon = forecast['code']
          forecast_measurement.date = Date.parse(forecast['date'])
          forecast_measurement.condition = forecast['text']
          forecast_measurement.high = Data::Temperature.new(metric)
          forecast_measurement.high << forecast['high'].to_f
          forecast_measurement.low = Data::Temperature.new(metric)
          forecast_measurement.low << forecast['low'].to_f
          forecasts << forecast_measurement
        end
      end
      forecasts
    end

    def self._build_location(data, geo=nil)
      raise ArgumentError unless data.is_a?(Hash)
      raise ArgumentError unless (geo.nil? || geo.is_a?(Data::Geo))
      location = Data::Location.new
      # use the geocoded data if available, otherwise get data from result
      if geo
        location.city = geo.locality
        location.state_code = geo.region
        location.country = geo.country
        location.country_code = geo.country_code
        location.latitude = geo.latitude
        location.longitude = geo.longitude
      else
        if data && data['location']
          location.city = data['location']['city']
          location.state_code = data['location']['region']
          location.country_code = data['location']['country']
          if data['item']
            location.latitude = data['item']['lat']
            location.longitude = data['item']['long']
          end
        end
      end
      location
    end

    def self._build_sun(data)
      raise ArgumentError unless data.is_a?(Hash)
      sun = nil
      if data && data['astronomy'] && data['item']
        local_rise = Data::LocalTime.parse(data['astronomy']['sunrise'])
        local_set = Data::LocalTime.parse(data['astronomy']['sunset'])
        sun = Data::Sun.new(local_rise, local_set)
      end
      sun || Data::Sun.new
    end

    # use HTTParty to get the current weather
    def self._fetch(query, metric=true)
      return unless query
      puts "fetch yahoo: #{query.q}" if Barometer::debug?
      options = {
        :p => query.format == :woe_id ? nil : query.q,
        :w => query.format == :woe_id ? query.q : nil,
        :u => (metric ? 'c' : 'f')
      }.delete_if {|k,v| v.nil? }
      r = self.get(
        "http://weather.yahooapis.com/forecastrss",
        :query => options,
        :format => :xml,
        :timeout => Barometer.timeout
      )
      r['rss']['channel']
    end

  end
end

Barometer::WeatherService.register(:yahoo, Barometer::WeatherService::Yahoo)
