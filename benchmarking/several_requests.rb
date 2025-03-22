require 'net/http'
require 'uri'

# Configuration
BASE_URL = 'http://localhost:3000/api/line/' # Replace with actual endpoint
PARAMETERS = (1..30).to_a
THREAD_COUNT = 30

def fetch_data(param)
  url = URI.parse("#{BASE_URL}#{param}")
  response = Net::HTTP.get_response(url)
  puts "Response for #{param}: #{response.code} - #{response.body[0..50]}..."
end

threads = []
PARAMETERS.each_slice((PARAMETERS.size.to_f / THREAD_COUNT).ceil) do |params|
  threads << Thread.new do
    params.each { |param| fetch_data(param) }
  end
end

# Wait for all threads to finish
threads.each(&:join)
