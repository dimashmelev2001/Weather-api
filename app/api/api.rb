require 'grape-swagger'
require 'net/http'

class API < Grape::API
  format :json
  prefix :api
  version 'v1', using: :path

  LANGUAGE = 'en'.freeze
  LOCATION_KEY = 13.freeze
  
  resource :weather do
    get :current do

      uri = URI("http://dataservice.accuweather.com/currentconditions/v1/#{LOCATION_KEY}")
      params = { apikey: ENV['API_KEY'], language: LANGUAGE }

      uri.query = URI.encode_www_form(params)
      
      response = Net::HTTP.get(uri)
      data = JSON.parse(response)

      if data
        temperature_metric = data.first.dig('Temperature', 'Metric', 'Value')
        present temperature_metric
      else
        error!('Unable to fetch current weather data', 500)
      end
    end

    get :historical do

      uri = URI("http://dataservice.accuweather.com/currentconditions/v1/#{LOCATION_KEY}/historical/24")
      params = { apikey: ENV['API_KEY'], language: LANGUAGE, details: true }

      uri.query = URI.encode_www_form(params)

      response = Net::HTTP.get(uri)
      data = JSON.parse(response)

      if data
        historical_data = data.map do |hourly_data|
          hourly_data.dig('Past24HourTemperatureDeparture', 'Metric', 'Value')
        end

        present historical_data
      else
        error!('Unable to fetch historical weather data', 500)
      end
    end

    resource :historical do
      get :max do
      
        uri = URI("http://dataservice.accuweather.com/currentconditions/v1/#{LOCATION_KEY}/historical/24")
        params = { apikey: ENV['API_KEY'], language: LANGUAGE, details: true }
      
        uri.query = URI.encode_www_form(params)
      
        response = Net::HTTP.get(uri)
        data = JSON.parse(response)
      
        if data
          max_temperature = data.first.dig('TemperatureSummary', 'Past24HourRange', 'Maximum', 'Metric', 'Value')
          present max_temperature
        else
          error!('Unable to fetch historical max weather data', 500)
        end
      end

      get :min do
      
        uri = URI("http://dataservice.accuweather.com/currentconditions/v1/#{LOCATION_KEY}/historical/24")
        params = { apikey: ENV['API_KEY'], language: LANGUAGE, details: true }
      
        uri.query = URI.encode_www_form(params)
      
        response = Net::HTTP.get(uri)
        data = JSON.parse(response)
      
        if data
          max_temperature = data.first.dig('TemperatureSummary', 'Past24HourRange', 'Minimum', 'Metric', 'Value')
          present max_temperature
        else
          error!('Unable to fetch historical min weather data', 500)
        end
      end

      get :avg do

        uri = URI("http://dataservice.accuweather.com/currentconditions/v1/#{LOCATION_KEY}/historical/24")
        params = { apikey: ENV['API_KEY'], language: LANGUAGE, details: true }
  
        uri.query = URI.encode_www_form(params)
  
        response = Net::HTTP.get(uri)
        data = JSON.parse(response)
  
        if data
          historical_data = data.map do |hourly_data|
            hourly_data.dig('Past24HourTemperatureDeparture', 'Metric', 'Value')
          end
  
          avg_temperature = (historical_data.sum  / historical_data.size.to_f).round(2)
          present avg_temperature
        else
          error!('Unable to fetch historical weather data', 500)
        end
      end
    end

    helpers do
      def get_forecast_data
        uri = URI("http://dataservice.accuweather.com/forecasts/v1/hourly/12hour/#{LOCATION_KEY}")
        params = { apikey: ENV['API_KEY'], language: LANGUAGE, details: true, metric: true }
        uri.query = URI.encode_www_form(params)
        response = Net::HTTP.get_response(uri)
        if response.is_a?(Net::HTTPSuccess)
          JSON.parse(response.body)
        else
          error!("Unable to fetch forecast data: #{response.code}", 500)
        end
      end

      def find_closest_forecast(forecast_data, timestamp)
        closest_forecast_point = forecast_data
                                          .select { |forecast_point| forecast_point['EpochDateTime'] <= timestamp }
                                          .max_by { |forecast_point| forecast_point['EpochDateTime'] }

        closest_forecast_temperature = closest_forecast_point.dig('Temperature', 'Value') if closest_forecast_point
        closest_forecast_temperature
      end
    end

    desc 'Find temperature closest to the timestamp'
    params do
      requires :timestamp, type: Integer, desc: 'Timestamp'
    end

    get :by_time do
      timestamp = params[:timestamp].to_i

      forecast_data = get_forecast_data

      if forecast_data.is_a?(Array) && !forecast_data.empty?
        closest_forecast = find_closest_forecast(forecast_data, timestamp)

        if closest_forecast
          present closest_forecast
        else
          error!('Temperature data not available for the timestamp', 404)
        end
      else
        error!('Unable to fetch forecast data', 500)
      end
    end
  end
  
  add_swagger_documentation
end