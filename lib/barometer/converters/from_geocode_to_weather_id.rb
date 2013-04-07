module Barometer
  module Converter
    class FromGeocodeToWeatherId
      def initialize(query)
        @query = query
      end

      def call
        return unless can_convert?

        response = WebService::WeatherID.fetch(@query)
        weather_id = format_response(response)
        @query.add_conversion(:weather_id, weather_id) if weather_id
      end

      private

      def can_convert?
        !!@query.get_conversion(:geocode)
      end

      def format_response(response)
        match = response.match(/loc id=[\\]?['|""]([0-9a-zA-Z]*)[\\]?['|""]/)
        match ? match[1] : nil
      end
    end
  end
end