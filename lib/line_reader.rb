module LineReader
  def self.read_line(file_path:, line_number:)
    validation_result = validate_arguments(
      file_path: file_path, line_number: line_number
    )

    return validation_result unless validation_result.success

    begin
      line_value = get_line_value(
        line_number: line_number.to_i,
        file_path: file_path,
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

  def self.validate_arguments(file_path:, line_number:)
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

    last_line_number = redis_connection.get("last_line_number").to_i

    if line_number >= last_line_number || line_number.negative?
      return Result.new(
        success: false,
        data: nil,
        error_status: ErrorStatus::INVALID_LINE_NUMBER,
        error_message: "The file has #{last_line_number} lines - line at index #{line_number} " +
                       "does not exist (index starts at 0, lasts index is #{line_number - 1})"
      )
    end


    Result.new(success: true, data: nil, error_status: nil, error_message: nil)
  end

  def self.get_line_value(line_number:, file_path:)
    # caching frequently accessed lines
    key = "#{file_path}:line:#{line_number}"
    cached_line_value = redis_connection.get(key)

    line_value = nil
    byte_position = redis_connection.hget(file_path, line_number).to_i
    File.open(file_path, "r") do |file|
      file.seek(byte_position, IO::SEEK_SET)
      line_value = file.readline.chomp
    end

    # caching line value for one hour to avoid several requests to redis for the same line
    redis_connection.set(key, line_value, ex: 3600) if cached_line_value.nil?

    line_value
  end
end
