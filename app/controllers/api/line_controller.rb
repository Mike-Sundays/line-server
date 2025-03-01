class Api::LineController < ApplicationController
  def show
    lines = File.readlines(ENV['FILE_PATH'])
    line_number = params[:line_number].to_i
    render json: {line_number: lines[line_number], path: ENV['FILE_PATH']}
  end
end
