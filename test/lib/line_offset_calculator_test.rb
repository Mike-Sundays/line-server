require 'test_helper'

class LineOffsetCalculatorTest < ActiveSupport::TestCase
  def test_calculates_line_offset_correctly
    file_path = "test/files/4_lines_of_text.txt"
    offset = LineOffsetCalculator.calculate(file_path)

    # each char in an ASCII file is 1 byte
    expected_offset = [0, 34, 69, 70]
    assert_equal expected_offset, offset
  end

  def test_error_for_non_existent_file
    file_path = "test/files/invalid.txt"
    assert_raises(RuntimeError) { LineOffsetCalculator.calculate(file_path) }
  end

  def test_error_for_no_path
    file_path = nil
    assert_raises(ArgumentError) { LineOffsetCalculator.calculate(file_path) }
  end
end