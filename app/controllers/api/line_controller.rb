class Api::LineController < ApplicationController
  def show
    path = ENV["FILE_PATH"]
    line_number = params[:line_number]
    redis = Rails.application.config.redis

    result = LineReader.read_line(
      file_path: path, line_number: line_number, redis: redis
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
