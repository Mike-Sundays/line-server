module LineOffsetCalculator
  def self.calculate(file_path)
    raise ArgumentError, "File path must be provided" if file_path.blank?

    offsets = []
    current_offset = 0

    begin
      File.open(file_path, "r") do |file|
        # each line only reads one file into memory, so memory is not a problem
        # the bottleneck here could be disk read speed
        file.each_line do |line|
          offsets << current_offset
          current_offset += line.bytesize
        end
      end
    rescue Errno::ENOENT
      raise "File not found: #{file_path}"
    end

    offsets
  end
end
