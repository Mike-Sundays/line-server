num_lines = 100000000
file_name = "large_file_#{num_lines}_lines.txt"

File.open(file_name, 'w') do |file|
  (1..num_lines).each do |i|
    file.puts "This is line number #{i}"
  end
end

puts "#{num_lines} lines have been written to #{file_name}."
