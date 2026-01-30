module QuotaChecker
  extend ActiveSupport::Concern

  included do
    before_action :ensure_user_quota_exists
  end

  private

  def ensure_user_quota_exists
    return if @current_user.user_quota.present?
    
    @current_user.create_user_quota(daily_limit: 10, used_today: 0)
  end

  def check_quota!
    quota = @current_user.user_quota
    
    unless quota.available?
      render json: {
        error: 'Quota exceeded',
        message: 'Bạn đã sử dụng hết quota. Vui lòng liên hệ admin để được cấp thêm quota.',
        quota: {
          total_limit: quota.daily_limit,
          used: quota.used_today,
          remaining: quota.remaining
        }
      }, status: :too_many_requests and return false
  end
    
    true
  end

  def increment_quota!
    @current_user.user_quota.increment_usage!
  end
end
