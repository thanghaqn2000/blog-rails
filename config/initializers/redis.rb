REDIS = Redis.new(
  host: ENV.fetch("REDIS_HOST", "localhost"),
  port: ENV.fetch("REDIS_PORT", 6379).to_i,
  db: ENV.fetch("REDIS_DB", 0).to_i,
  password: ENV.fetch("REDIS_PASSWORD", nil)
)
