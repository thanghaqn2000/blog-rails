# Ghi last_active_at xuống DB tối đa mỗi 15 phút / user.
# Redis SET NX + TTL: chỉ khi "thắng" mới UPDATE; các request khác trong cửa sổ bị chặn.
class UserLastActiveSync
  FLUSH_INTERVAL_SECONDS = 15.minutes.to_i
  KEY_PREFIX = "last_active_db_flush:"

  def self.call(user_id)
    return if user_id.blank?

    key = "#{KEY_PREFIX}#{user_id}"
    begin
      if REDIS.set(key, "1", nx: true, ex: FLUSH_INTERVAL_SECONDS)
        User.where(id: user_id).update_all(last_active_at: Time.current)
      end
    rescue ActiveRecord::ActiveRecordError => e
      Rails.logger.warn("[UserLastActiveSync] DB: #{e.class}: #{e.message}")
    rescue Redis::BaseError => e
      Rails.logger.warn("[UserLastActiveSync] Redis: #{e.class}: #{e.message}")
    rescue StandardError => e
      # Chạy trong after_action: tuyệt đối không để lỗi làm fail request chính.
      Rails.logger.warn("[UserLastActiveSync] Unexpected: #{e.class}: #{e.message}")
    end
  end
end
