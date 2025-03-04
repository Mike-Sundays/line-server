ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"

# This runs before each test, clearing up the redis test container,
# and then to populate redis as if the file had been read.
redis = Rails.application.config.redis
redis.flushall

SaveLineOffsetToRedis.run(file_path: "./test/files/4_lines_of_text.txt", redis: redis)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Add more helper methods to be used by all tests here...
  end
end
