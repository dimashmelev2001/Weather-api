require 'rack/test'
require 'rspec'

require './app/api/api.rb'

def app
  API
end

describe 'Weather Api' do
  include Rack::Test::Methods

  context 'GET /api/weather/current' do
    it 'returns current temperature' do
      get '/api/weather/current'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to include('temperature_metric')
    end
  end

  context 'GET /api/weather/historical' do
    it 'returns historical data' do
      get '/api/weather/historical'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to include('historical_data')
    end
  end

  context 'GET /api/weather/historical/max' do
    it 'returns max historical temperature' do
      get '/api/weather/historical/max'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to include('max_temperature')
    end
  end

  context 'GET /api/weather/historical/min' do
    it 'returns min historical temperature' do
      get '/api/weather/historical/min'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to include('min_temperature')
    end
  end

  context 'GET /api/weather/historical/avg' do
    it 'returns avg historical temperature' do
      get '/api/weather/historical/avg'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to include('avg_temperature')
    end
  end

  context 'GET /api/weather/by_time' do
    it 'returns temperature closest to timestamp' do
      timestamp = Time.now.to_i
      get "/api/weather/by_time?timestamp=#{timestamp}"
      expect(last_response.status).to eq(200)
      json_response = JSON.parse(last_response.body)
      expect(json_response).to include('closest_forecast')
    end
  end
end
