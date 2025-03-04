module SaveLineOffsetToRedis
  def self.run(file_path:, redis:)
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
        end
      end

      # saving in batch to avoid various redis requests
      redis.hmset(file_path, *offset_hash.flatten)

      # clearing up the memory occupied by the hash without waiting for the garbage collector
      offset_hash.clear

      redis.set("last_line_number", line_number.to_s)

    rescue Errno::ENOENT
      raise "File not found: #{file_path}"
    end

  end
end
