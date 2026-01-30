class UserQuota < ApplicationRecord
  self.table_name = 'user_quotas'  # Explicit table name
  self.primary_key = 'user_id'
  
  belongs_to :user

  validates :user_id, presence: true, uniqueness: true
  validates :daily_limit, numericality: { greater_than_or_equal_to: 0 }
  validates :used_today, numericality: { greater_than_or_equal_to: 0 }

  # Kiểm tra xem user còn quota không
  def available?
    used_today < daily_limit
  end

  # Lấy số lượng quota còn lại
  def remaining
    [daily_limit - used_today, 0].max
  end

  # Tăng usage
  def increment_usage!
    increment!(:used_today)
  end

  # Admin cấp thêm quota (reset về 0 hoặc tăng limit)
  def grant_quota!(new_limit)
    update!(
      daily_limit: new_limit,
      used_today: 0
    )
  end

  # Admin reset usage về 0 (giữ nguyên limit)
  def reset_usage!
    update!(used_today: 0)
  end
end
