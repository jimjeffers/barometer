require_relative 'query'

module Barometer
  module WeatherService
    class Yahoo
      class Api < Utils::Api
        def initialize(query)
          @query = Yahoo::Query.new(query)
        end

        def url
          'http://weather.yahooapis.com/forecastrss'
        end

        def unwrap_nodes
          ['rss', 'channel']
        end
      end
    end
  end
end
