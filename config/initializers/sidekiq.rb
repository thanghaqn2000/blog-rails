require 'sidekiq'
require 'sidekiq/web'

# Redis configuration for both server and client
redis_config = {
  host: ENV.fetch('REDIS_HOST', 'localhost'),
  port: ENV.fetch('REDIS_PORT', 6379),
  db: ENV.fetch('REDIS_DB', 0),
  password: ENV.fetch('REDIS_PASSWORD', nil)
}

Sidekiq.configure_server { |config| config.redis = redis_config }
Sidekiq.configure_client { |config| config.redis = redis_config }

# Protect Sidekiq Web UI
Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  [user, password] == [ENV.fetch('SIDEKIQ_USERNAME', 'admin'), ENV.fetch('SIDEKIQ_PASSWORD', 'password')]
end
