require 'connection_pool'

# Create a connection pool with reusable file handlers
FILE_HANDLER_POOL = ConnectionPool.new(size: 64, timeout: 5) do
  # Each connection creates its own file handler
  File.open(ENV["FILE_PATH"], "r")
end

# Ensure all file handlers are closed on shutdown
at_exit do
  FILE_HANDLER_POOL.shutdown { |file| file.close }
end
