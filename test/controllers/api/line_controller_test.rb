require "test_helper"

class Api::LineControllerTest < ActionDispatch::IntegrationTest
  def setup
    @redis = Rails.application.config.redis
  end

  test "should return correct line for a valid file" do
    ENV["FILE_PATH"] = "./test/files/4_lines_of_text.txt"

    get api_show_line_path(line_number: 1)
    assert_response :success
    assert_includes response.body, "Whispers of adventure in the wind"
  end

  test "should return empty line if file has one" do
    ENV["FILE_PATH"] = "./test/files/4_lines_of_text.txt"

    get api_show_line_path(line_number: 2)
    assert_includes response.body, ""
    assert_response 200
  end

  test "should return 500 for a file not found" do
    ENV["FILE_PATH"] = "./test/files/b.txt"

    get api_show_line_path(line_number: 1)
    assert_response 500
  end

  test "should return 500 for no path" do
    ENV["FILE_PATH"] = nil

    get api_show_line_path(line_number: 1)
    assert_response 500
  end

  test "should return 404 for invalid line number (string)" do
    ENV["FILE_PATH"] = "./test/files/4_lines_of_text.txt"

    get api_show_line_path(line_number: "abc")
    assert_response 404
  end

  test "should return 413 for lines outside the range of a file" do
    ENV["FILE_PATH"] = "./test/files/4_lines_of_text.txt"

    get api_show_line_path(line_number: 6)
    assert_response 413
  end

  test "should return 413 for negative lines" do
    ENV["FILE_PATH"] = "./test/files/4_lines_of_text.txt"

    get api_show_line_path(line_number: -1)
    assert_response 413
  end

end
