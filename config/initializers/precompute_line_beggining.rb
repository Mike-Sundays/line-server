require_relative "../../lib/line_offset_calculator"

unless Rails.env.test?
  Rails.application.config.line_byte_position = LineOffsetCalculator.calculate(ENV["FILE_PATH"])
end
