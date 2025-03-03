require 'test_helper'

class LineReaderTest < ActiveSupport::TestCase
  def setup
    @file_path = "test/files/4_lines_of_text.txt"
    @line_byte_positions = [0, 34, 69, 70]
  end
  def test_read_lines_works
    result = LineReader.read_line(
      file_path: @file_path, line_byte_position: @line_byte_positions, line_number: 1
    )

    assert result.success
    assert_equal "Whispers of adventure in the wind.", result.data
  end

  def test_read_lines_works_2
    result = LineReader.read_line(
      file_path: @file_path, line_byte_position: @line_byte_positions, line_number: 2
    )

    assert result.success
    assert_equal "", result.data
  end

  def test_read_lines_with_invalid_line_number_after_end_of_file
    result = LineReader.read_line(
      file_path: @file_path, line_byte_position: @line_byte_positions, line_number: 5
    )

    assert !result.success
    assert_equal result.error_status, ErrorStatus::INVALID_LINE_NUMBER
  end

  def test_read_lines_with_invalid_line_number_negative
    result = LineReader.read_line(
      file_path: @file_path, line_byte_position: @line_byte_positions, line_number: -1
    )

    assert !result.success
    assert_equal result.error_status, ErrorStatus::INVALID_LINE_NUMBER
  end

  def test_read_lines_with_file_not_found
    result = LineReader.read_line(
      file_path: "blabla", line_byte_position: @line_byte_positions, line_number: 5
    )

    assert !result.success
    assert_equal result.error_status, ErrorStatus::FILE_NOT_FOUND
  end

  def test_read_lines_with_line_number_not_an_integer
    result = LineReader.read_line(
      file_path: "blabla", line_byte_position: @line_byte_positions, line_number: "frgrs"
    )

    assert !result.success
    assert_equal result.error_status, ErrorStatus::LINE_NUMBER_NOT_AN_INTEGER
  end
end