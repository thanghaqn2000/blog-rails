require "digest"

class Api::Auth::PasswordResetRateLimiter
  INTERVAL_SECONDS = 3.minutes.to_i
  KEY_PREFIX = "forgot_password_rate_limit:".freeze

  # Giới hạn 1 yêu cầu / 3 phút / email.
  # Trả về true nếu được phép tạo reset token.
  def self.allowed?(email)
    return false if email.blank?

    normalized = email.strip.downcase
    key = "#{KEY_PREFIX}#{Digest::SHA256.hexdigest(normalized)}"

    begin
      REDIS.set(key, "1", nx: true, ex: INTERVAL_SECONDS).present?
    rescue Redis::BaseError => e
      Rails.logger.warn("[PasswordResetRateLimiter] Redis: #{e.class}: #{e.message}")
      # Best-effort: nếu Redis lỗi thì vẫn cho chạy để không chặn luồng chính.
      true
    end
  end
end

