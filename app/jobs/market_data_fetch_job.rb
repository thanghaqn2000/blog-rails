require "net/http"
require "securerandom"

class MarketDataFetchJob < ApplicationJob
  queue_as :critical

  REDIS_KEY_GOLD_PRICES   = "market:gold_prices".freeze
  REDIS_KEY_EXCHANGE_RATES = "market:exchange_rates".freeze
  LOCK_KEY = "market:fetch_lock".freeze
  REDIS_TTL = 3600 # seconds (1 hour)
  LOCK_TTL = 300 # seconds (so lock doesn't expire mid-fetch)

  def perform
    return unless acquire_lock

    begin
      gold_exists = REDIS.exists(REDIS_KEY_GOLD_PRICES) == 1
      exchange_exists = REDIS.exists(REDIS_KEY_EXCHANGE_RATES) == 1

      data = fetch_market_data
      if data.nil?
        # Nếu call vnstock thất bại tạm thời (504/timeout), giữ lại dữ liệu cũ bằng cách gia hạn TTL.
        REDIS.expire(REDIS_KEY_GOLD_PRICES, REDIS_TTL) if gold_exists
        REDIS.expire(REDIS_KEY_EXCHANGE_RATES, REDIS_TTL) if exchange_exists
        return
      end

      now = data["fetched_at"] || Time.current.iso8601

      if data["gold_prices"].present?
        gold_payload = { data: data["gold_prices"], fetched_at: now }.to_json
        REDIS.setex(REDIS_KEY_GOLD_PRICES, REDIS_TTL, gold_payload)
        ActionCable.server.broadcast("market_data", { type: "gold_prices", data: data["gold_prices"], fetched_at: now })
      elsif gold_exists
        # Không có dữ liệu mới => gia hạn TTL để tránh cache hết hạn dẫn tới data nil
        REDIS.expire(REDIS_KEY_GOLD_PRICES, REDIS_TTL)
      end

      if data["exchange_rates"].present?
        exchange_payload = { data: data["exchange_rates"], fetched_at: now }.to_json
        REDIS.setex(REDIS_KEY_EXCHANGE_RATES, REDIS_TTL, exchange_payload)
        ActionCable.server.broadcast("market_data", { type: "exchange_rates", data: data["exchange_rates"], fetched_at: now })
      elsif exchange_exists
        REDIS.expire(REDIS_KEY_EXCHANGE_RATES, REDIS_TTL)
      end

      log_errors(data["errors"]) if data["errors"].present?
    ensure
      release_lock
    end
  end

  private

  def fetch_market_data
    base_url = ENV.fetch("STOCK_API_URL", "http://stock-api:8000")
    uri = URI("#{base_url}/api/market_data")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = 15
    http.read_timeout = 15

    response = http.get(uri.request_uri)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("[MarketDataFetchJob] HTTP #{response.code}: #{response.body}")
      return nil
    end

    JSON.parse(response.body)
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.error("[MarketDataFetchJob] Timeout: #{e.message}")
    nil
  rescue Errno::ECONNREFUSED => e
    Rails.logger.error("[MarketDataFetchJob] Connection refused: #{e.message}")
    nil
  rescue JSON::ParserError => e
    Rails.logger.error("[MarketDataFetchJob] Invalid JSON: #{e.message}")
    nil
  end

  def acquire_lock
    @lock_token = SecureRandom.uuid
    REDIS.set(LOCK_KEY, @lock_token, nx: true, ex: LOCK_TTL)
  end

  def release_lock
    script = <<~LUA
      if redis.call("get", KEYS[1]) == ARGV[1] then
        return redis.call("del", KEYS[1])
      else
        return 0
      end
    LUA
    REDIS.eval(script, keys: [LOCK_KEY], argv: [@lock_token])
  end

  def log_errors(errors)
    errors.each { |err| Rails.logger.warn("[MarketDataFetchJob] #{err}") }
  end
end
