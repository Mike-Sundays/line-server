require 'test_helper'

class SaveLineOffsetToRedisTest < ActiveSupport::TestCase
  def setup
    @redis = redis_connection
  end

  def test_calculates_line_offset_correctly
    file_path = "./test/files/4_lines_of_text.txt"
    SaveLineOffsetToRedis.run(file_path: file_path, num_processes: 1)

    redis_offsets = @redis.hgetall("line_offsets:#{file_path}")

    expected_offset = {
      "0" => "0",
      "1" => "34",
      "2" => "69",
      "3" => "70"
    }

    assert_equal expected_offset, redis_offsets

  end

  def test_error_for_non_existent_file
    file_path = "./test/files/invalid.txt"
    assert_raises(Errno::ENOENT) { SaveLineOffsetToRedis.run(file_path: file_path, num_processes: 1) }
  end

  def test_error_for_no_path
    file_path = nil
    assert_raises(ArgumentError) { SaveLineOffsetToRedis.run(file_path:file_path, num_processes: 1) }
  end
end