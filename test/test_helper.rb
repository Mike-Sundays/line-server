ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"

Rails.application.config.line_byte_position = LineOffsetCalculator.calculate("./test/files/4_lines_of_text.txt")

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Add more helper methods to be used by all tests here...
  end
end
