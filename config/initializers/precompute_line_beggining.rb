require_relative "../../lib/save_line_offset_to_redis"

ENV["FILE_PATH"] = "./benchmarking/large_file_100000_lines.txt"

=begin
ENV["FILE_PATH"] = "./test/files/4_lines_of_text.txt"
=end

unless Rails.env.test?
  file_path = ENV["FILE_PATH"]

  if file_path && File.exist?(file_path)
    redis_client = redis_connection

=begin
    cached_data = redis_client.exists?("line_offsets:#{file_path}")
=end
=begin

    if cached_data
      puts "File at #{file_path} already precomputed. Skipping computation."
      return
    end
=end

    redis_client.flushall
    batch_size = 10_000
    num_processes = 4

    time = Benchmark.realtime do
      SaveLineOffsetToRedis.run(
        file_path: file_path,
        batch_size: batch_size,
        num_processes: num_processes
      )
    end
    human_readable_file_size = ActiveSupport::NumberHelper.number_to_human_size(File.size(file_path))


    # Log the operation details.
    puts "File at #{file_path} precomputed in #{time.round(6)} seconds with #{num_processes} processes. File size: #{human_readable_file_size}."
  end

end
