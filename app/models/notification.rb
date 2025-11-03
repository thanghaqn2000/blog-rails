class Notification < ApplicationRecord
  belongs_to :user
  
  # Disable STI vì Rails nghĩ column 'type' là cho inheritance
  self.inheritance_column = :_type_disabled
  
  enum :type, {
    sent_now: 0,
    scheduled: 1
  }
  enum :status, {
    pending: 0,
    sent: 1,
    read: 2
  }

  validates :title, presence: { message: "Tiêu đề là bắt buộc" }
  validates :content, presence: { message: "Nội dung là bắt buộc" }
  validates :scheduled_at, presence: { message: "Thời gian lên lịch là bắt buộc" }, if: :scheduled?
  validates :scheduled_at, comparison: { greater_than: Time.current, message: "Thời gian lên lịch phải ở tương lai" }, if: :scheduled?

  scope :scheduled_for_sending, -> { where(type: :scheduled, status: :pending).where('scheduled_at <= ?', Time.current) }
  scope :pending, -> { where(status: :pending) }

  # after_create :schedule_notification, if: :should_send_immediately?
  # after_update :reschedule_notification, if: :should_reschedule?

  def send_now!
    # Gửi đến tất cả users (mặc định)
    SendNotificationJob.perform_later(id)
  end

  def schedule_notification
    SendNotificationJob.set(wait_until: scheduled_at).perform_later(id)
    Rails.logger.info("[Notification] Scheduled notification #{id} for #{scheduled_at}")
  end

  def send_to_topic!(topic)
    # Gửi đến topic thông qua Firebase service
    service = Firebase::PushNotificationService.new(notification: self)
    service.send_to_topic(topic)
  end

  def send_to_devices!(device_tokens)
    # Gửi đến danh sách device tokens cụ thể
    service = Firebase::PushNotificationService.new(
      notification: self, 
      device_tokens: device_tokens
    )
    service.perform
  end

  def mark_as_sent!
    update!(status: :sent, sent_at: Time.current)
  end

  def mark_as_read!
    update!(status: :read)
  end

  private

  def should_send_immediately?
    sent_now? && pending?
  end

  def should_reschedule?
    scheduled? && scheduled_at_changed? && pending?
  end

  # def schedule_notification
  #   if scheduled? && scheduled_at.present?
  #     # Lên lịch gửi notification tại thời điểm scheduled_at (gửi đến tất cả users)
  #     SendNotificationJob.set(wait_until: scheduled_at).perform_later(id)
  #     Rails.logger.info("[Notification] Scheduled notification #{id} for #{scheduled_at}")
  #   else
  #     # Nếu không có scheduled_at thì gửi ngay
  #     send_now!
  #   end
  # end

  def reschedule_notification
    # Cancel existing job and schedule new one
    # Note: This is a simplified version. In production, you might want to
    # implement job cancellation using job IDs
    SendNotificationJob.set(wait_until: scheduled_at).perform_later(id)
  end
end
