class Api::LineController < ApplicationController
  def show
    line_byte_position = Rails.application.config.line_byte_position
    line_number = params[:line_number]
    path = ENV["FILE_PATH"]

    result = LineReader.read_line(
      file_path: path, line_number: line_number, line_byte_position: line_byte_position
    )

    if result.success
      render json: { value: result.data }, status: :ok
    else
      render json: { error: result.error_message }, status: map_http_status(result.error_status)
    end
  end

  private

  def map_http_status(error_status)
    case error_status
    when ErrorStatus::LINE_NUMBER_NOT_AN_INTEGER
      404
    when ErrorStatus::INVALID_LINE_NUMBER
      413
    else
      500
    end
  end

end
