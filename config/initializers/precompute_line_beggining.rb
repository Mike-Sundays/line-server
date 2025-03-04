require_relative "../../lib/save_line_offset_to_redis"

=begin
ENV["FILE_PATH"] = "./large_file_10000000_lines.txt"
=end

=begin
ENV["FILE_PATH"] = "./test/files/4_lines_of_text.txt"
=end

unless Rails.env.test?
  file_path = ENV["FILE_PATH"]

  if file_path && File.exist?(file_path)
    redis_client = redis_connection


    cached_data = redis_client.exists?(file_path)

    if cached_data
      puts "File at #{file_path} already precomputed. Skipping computation."
      return
    end

    start_time = Time.now

    SaveLineOffsetToRedis.run(file_path: file_path, batch_size: 10000)

    end_time = Time.now

    time_taken = end_time - start_time

    # Gather file metadata.
    file_size = File.size(file_path)
    human_readable_file_size = ActiveSupport::NumberHelper.number_to_human_size(file_size)


    # Log the operation details.
    puts "File at #{file_path} precomputed in #{time_taken} seconds. File size: #{human_readable_file_size}."
  end

end
