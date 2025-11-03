class SendNotificationJob < ApplicationJob
  queue_as :default

  def perform(notification_id, options = {})
    notification = Notification.find_by(id: notification_id)
    return unless notification

    service = Firebase::PushNotificationService.new(
      notification: notification
    )
    
    result = service.perform
    log_result(notification, result)
  end

  private

  def log_result(notification, result)
    timestamp = Time.current.strftime("%Y-%m-%d %H:%M:%S")
    
    if result[:success]
      Rails.logger.info("[SendNotificationJob] [#{timestamp}] ✅ Successfully sent notification #{notification.id}")
      notification.update(sent_at: Time.current) if notification.respond_to?(:sent_at)
    else
      Rails.logger.error("[SendNotificationJob] [#{timestamp}] ❌ Failed to send notification #{notification.id}: #{result[:error]}")
      if result[:error]&.include?("unexpected character")
        Rails.logger.error("[SendNotificationJob] This looks like a JSON parsing error. Please check your FIREBASE_SERVICE_ACCOUNT_JSON environment variable.")
        Rails.logger.error("[SendNotificationJob] Make sure it contains valid JSON and all required fields.")
      end
    end
    result
  end
end
