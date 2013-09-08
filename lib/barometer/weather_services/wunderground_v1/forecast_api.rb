require 'barometer/weather_services/wunderground_v1/query'

module Barometer
  module WeatherService
    class WundergroundV1
      class ForecastApi < Api
        def initialize(query)
          @query = WundergroundV1::Query.new(query)
        end

        def url
          'http://api.wunderground.com/auto/wui/geo/ForecastXML/index.xml'
        end

        def unwrap_nodes
          ['forecast']
        end
      end
    end
  end
end