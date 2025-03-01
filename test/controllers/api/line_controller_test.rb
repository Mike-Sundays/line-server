require "test_helper"

class Api::LineControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get api_show_line_path(line_number: 1)
    assert_response :success
    assert_includes response.body, 'b'
  end
end
