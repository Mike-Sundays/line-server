module ErrorStatus
  FILE_NOT_FOUND = :file_not_found
  INVALID_LINE_NUMBER = :invalid_line_number
  UNKNOWN_ERROR = :unknown_error
  LINE_NUMBER_NOT_AN_INTEGER = :line_number_not_an_integer
end

class Result
  attr_reader :success, :data, :error_message, :error_status

  def initialize(success:, data: nil, error_status: nil, error_message: nil)
    @success = success
    @data = data
    @error_status = error_status
    @error_message = error_message
  end
end
