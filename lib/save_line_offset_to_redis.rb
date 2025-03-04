module SaveLineOffsetToRedis
  def self.run(file_path:, batch_size: 10000)
    raise ArgumentError, "File path must be provided" if file_path.blank?

    offset_hash = {}
    line_number = 0
    current_offset = 0

    begin
      File.open(file_path, "r") do |file|
        # each line only reads one file into memory, so memory is not a problem
        # the bottleneck here could be disk read speed
        file.each_line do |line|
          offset_hash[line_number] = current_offset

          # Increment offset and line number
          current_offset += line.bytesize
          line_number += 1

          if (line_number % batch_size).zero?
            redis_connection.hmset(file_path, *offset_hash.flatten)
            # clearing up memory
            offset_hash.clear
          end
        end

        # saving last batch if there are some remaining values
        redis_connection.hmset(file_path, *offset_hash.flatten) unless offset_hash.empty?
        offset_hash.clear

        redis_connection.set("last_line_number", line_number.to_s)
      end
    rescue Errno::ENOENT
      raise "File not found: #{file_path}"
    end

  end
end
