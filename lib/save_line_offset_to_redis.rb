require "parallel"

module SaveLineOffsetToRedis
  def self.run(file_path:, batch_size: 10000, num_processes: 4)
    raise ArgumentError, "File path must be provided" if file_path.blank?

    # First pass: quickly count lines and get file size
    total_lines = 0
    File.foreach(file_path) { total_lines += 1 }

    # Calculate chunks for parallel processing
    chunks = calculate_chunks(num_processes, total_lines)

    # Process chunks in parallel
    Parallel.each(chunks, in_processes: num_processes) do |(start_line, end_line)|
      process_chunk(file_path, start_line, end_line, batch_size)
    end

    save_last_line_number(total_lines)
  end

  private

  def self.calculate_chunks(num_processes, total_lines)
    chunk_size = (total_lines / num_processes.to_f).ceil
    chunks = (0...num_processes).map do |i|
      start_line = i * chunk_size
      end_line = [start_line + chunk_size, total_lines].min # first case for normal chunk, second for last chunk
      [start_line, end_line]
    end
    chunks
  end

  def self.process_chunk(file_path, start_line, end_line, batch_size)
    offset_hash = {}

    # Calculate the starting byte offset for this chunk
    current_offset = 0

    File.open(file_path, "r") do |file|
      # this is necessary so that each process that starts processing a
      # chunk starts from the correct offset
      # Example: If there are 4 processes for a file of 100 000 lines,
      # process 2 must start at the byte offset for line 25 000
      start_line.times { current_offset += file.readline.bytesize }

      # Process lines in the chunk
      file.each_line.with_index(start_line) do |line, line_number|
        break if line_number >= end_line

        offset_hash[line_number] = current_offset
        current_offset += line.bytesize

        if reached_end_of_batch?(batch_size, offset_hash)
          save_redis_batch(file_path, offset_hash)
          offset_hash.clear
        end
      end
    end

    # Save remaining offsets if end of last batch was not reached
    save_redis_batch(file_path, offset_hash) unless offset_hash.empty?
  end

  def self.reached_end_of_batch?(batch_size, offset_hash)
    offset_hash.size >= batch_size
  end

  def self.save_redis_batch(file_path, offset_hash)
    redis_connection.pipelined do |pipe|
      pipe.hmset("line_offsets:#{file_path}", *offset_hash.flatten)
    end
  end

  def self.save_last_line_number(total_lines)
    redis_connection.set("line_offsets:last_line_number", total_lines.to_s)
  end
end
