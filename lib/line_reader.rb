module LineReader

  def self.read_line(file_path:, line_byte_position:, line_number:)
    validation_result = validate_arguments(
      file_path: file_path, line_byte_position: line_byte_position, line_number: line_number
    )

    return validation_result unless validation_result.success

    begin
      line_value = get_line_value(
        line_byte_position: line_byte_position,
        line_number: line_number.to_i,
        file_path: file_path
      )

      Result.new(
        success: true,
        data: line_value,
        error_status: nil,
        error_message: nil
      )
    rescue StandardError => e
      Result.new(
        success: false,
        data: nil,
        error_status: ErrorStatus::UNKNOWN_ERROR,
        error_message: e.message
      )
    end

  end

  private

  def self.validate_arguments(file_path:, line_byte_position:, line_number:)
    begin
      line_number = Integer(line_number)
    rescue ArgumentError
      return Result.new(
        success: false,
        data: nil,
        error_status: ErrorStatus::LINE_NUMBER_NOT_AN_INTEGER,
        error_message: "'#{line_number}' is not a valid line number"
      )
    end

    unless File.exist?(file_path.to_s)
      return Result.new(
        success: false,
        data: nil,
        error_status: ErrorStatus::FILE_NOT_FOUND,
        error_message: "File not found at #{file_path}")
    end

    number_of_lines = line_byte_position.length

    if line_number >= number_of_lines || line_number.negative?
      return Result.new(
        success: false,
        data: nil,
        error_status: ErrorStatus::INVALID_LINE_NUMBER,
        error_message: "The file has #{number_of_lines} lines - line at index #{line_number} does not exist"
      )
    end


    Result.new(success: true, data: nil, error_status: nil, error_message: nil)
  end

  def self.get_line_value(line_byte_position:, line_number:, file_path:)
    line_value = nil
    File.open(file_path, "r") do |file|
      file.seek(line_byte_position[line_number], IO::SEEK_SET)
      line_value = file.readline.chomp
    end
    line_value
  end
end
