ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"

# This runs before each test, clearing up the redis test container,
# and then to populate redis as if the file had been read.
ENV["FILE_PATH"] = "./test/files/4_lines_of_text.txt"

redis_connection.flushall
SaveLineOffsetToRedis.run(file_path: ENV["FILE_PATH"], num_processes: 1)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

  end
end
