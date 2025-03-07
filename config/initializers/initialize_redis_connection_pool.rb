def redis_connection
  Rails.application.config.redis.with { |conn| conn }
end
