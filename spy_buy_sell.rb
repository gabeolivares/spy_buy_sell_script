require 'net/http'
require 'json'
require 'technical_analysis'

def fetch_stock_data(stock_symbol, api_key)
  base_url = "https://financialmodelingprep.com/api/v3/historical-price-full/#{stock_symbol}?apikey=#{api_key}"
  response = Net::HTTP.get(URI(base_url))
  json_response = JSON.parse(response)

  if json_response["historical"].nil?
    return nil
  end

  json_response["historical"].reverse
end

def rsi(input_data, period)
  TechnicalAnalysis::Rsi.calculate(input_data, period: period, price_key: :close)
end

def knn_strategy(prices)
    short_period = 14
    long_period = 28
    base_k = 252
    k = Math.sqrt(base_k).floor
  
    rsi_short = rsi(prices, short_period)
    rsi_long = rsi(prices, long_period)
  
    profits = []
  
    rsi_short.each_with_index do |rsi_value, index|
      next if index < k || rsi_value.nil? || rsi_long[index].nil?
  
      distances = []
      directions = []
  
      (index - k...index).each do |i|
        next if rsi_short[i].nil? || rsi_long[i].nil?
  
        distance = Math.sqrt((rsi_short[i].rsi - rsi_value.rsi) ** 2 + (rsi_long[i].rsi - rsi_long[index].rsi) ** 2)
        direction = prices[i][:close] < prices[i + 1][:close] ? 1 : -1
  
        distances << distance
        directions << direction
      end
  
      sorted_indices = distances.each_with_index.sort.map(&:last)
      nearest_directions = sorted_indices.first(k).map { |i| directions[i] }
  
      prediction = nearest_directions.inject(0, :+)
      profit = prediction * (prices[index + 1][:close] - prices[index][:close])
      profits << profit
    end
  
    profits.last(15)
  end
  

stock_symbol = 'SPY'
api_key = '5002d75ca9d44e46824fad1ed007dab7'

stock_data = fetch_stock_data(stock_symbol, api_key)

if stock_data.nil?
  puts "Failed to fetch stock data. Please check the API key and try again."
  exit
end

prices = stock_data.map { |data| { date_time: data['date'], close: data['close'].to_f } }
profits = knn_strategy(prices)

profits.each_with_index do |profit, index|
  puts "Profit for day #{index + 1}: #{profit.round(2)}"
end

total_profit = profits.inject(0, :+)
puts "\nTotal profit for the last 15 days: #{total_profit.round(2)}"