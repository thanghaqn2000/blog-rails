require "net/http"
require "uri"
require "json"
require "googleauth"

class Firebase::PushNotificationService
  FCM_ENDPOINT = "https://fcm.googleapis.com/v1/projects/#{ENV['FIREBASE_PROJECT_ID']}/messages:send"
  
  def initialize(notification:)
    @notification = notification
    @device_tokens = get_all_fcm_tokens
  end

  def perform
    return error_result("Danh sách device tokens không được để trống") if @device_tokens.blank?
    return error_result("Notification không hợp lệ") unless @notification

    config_error = validate_firebase_config
    return error_result(config_error) if config_error

    send_to_multiple_devices(@device_tokens)
  rescue => e
    Rails.logger.error("[FCM Service] Error: #{e.message}")
    error_result("Lỗi hệ thống: #{e.message}")
  end

  def send_to_multiple_devices(device_tokens)
    return error_result("Danh sách device tokens không được để trống") if device_tokens.blank?
    return error_result("Notification không hợp lệ") unless @notification

    # Validate Firebase configuration before proceeding
    config_error = validate_firebase_config
    return error_result(config_error) if config_error

    access_token = get_access_token
    results = []
    
    device_tokens.each do |token|
      next if token.blank?
      
      begin
        response = send_single_notification(access_token, token)
        if response.code.to_i == 200
          results << { success: true, token: token, message: "Sent successfully" }
        else
          results << { success: false, token: token, error: response.body }
        end
      rescue => e
        Rails.logger.error("[FCM Service] Error sending to token #{token}: #{e.message}")
        results << { success: false, token: token, error: e.message }
      end
    end
    
    success_count = results.count { |r| r[:success] }
    
    # Cập nhật notification status nếu có ít nhất 1 thành công
    if success_count > 0
      update_notification_status
    end
    
    {
      success: success_count > 0,
      message: "Đã gửi thành công #{success_count}/#{device_tokens.count} notifications",
      total_tokens: device_tokens.count,
      success_count: success_count,
      failed_count: device_tokens.count - success_count,
      results: results
    }
  end

  private

  attr_reader :notification, :device_tokens

  def get_all_fcm_tokens
    User.where.not(fcm_token: [nil, '']).pluck(:fcm_token).compact.uniq
  end

  def validate_firebase_config
    return "FIREBASE_PROJECT_ID environment variable is not set" if ENV['FIREBASE_PROJECT_ID'].blank?
    return "FIREBASE_SERVICE_ACCOUNT_JSON environment variable is not set" if ENV['FIREBASE_SERVICE_ACCOUNT_JSON'].blank?
    
    # Test JSON parsing
    begin
      service_account = JSON.parse(ENV['FIREBASE_SERVICE_ACCOUNT_JSON'])
      required_fields = ['type', 'project_id', 'private_key', 'client_email']
      missing_fields = required_fields - service_account.keys
      
      if missing_fields.any?
        return "FIREBASE_SERVICE_ACCOUNT_JSON is missing required fields: #{missing_fields.join(', ')}"
      end
    rescue JSON::ParserError => e
      return "Invalid FIREBASE_SERVICE_ACCOUNT_JSON format: #{e.message}. Please check your environment variable contains valid JSON."
    end
    
    nil # No errors
  end

  def get_access_token
    service_account_json = ENV["FIREBASE_SERVICE_ACCOUNT_JSON"]
    raise "FIREBASE_SERVICE_ACCOUNT_JSON environment variable is not set" if service_account_json.blank?
    
    begin
      json_key = JSON.parse(service_account_json)
    rescue JSON::ParserError => e
      raise "Invalid FIREBASE_SERVICE_ACCOUNT_JSON format: #{e.message}. Please check your environment variable contains valid JSON."
    end
    
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(json_key.to_json),
      scope: ["https://www.googleapis.com/auth/firebase.messaging"]
    )
    authorizer.fetch_access_token!
    authorizer.access_token
  end

  def send_single_notification(access_token, device_token)
    uri = URI(FCM_ENDPOINT)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{access_token}"
    request['Content-Type'] = 'application/json'
    request.body = build_message_payload(device_token).to_json

    response = http.request(request)
    Rails.logger.info("[FCM Service] Response for #{device_token[0..10]}***: #{response.code} - #{response.body}")
    response
  end

  def build_message_payload(device_token)
    {
      message: {
        token: device_token,
        notification: {
          title: @notification.title,
          body: @notification.content,
          image: @notification.image_url
        }.compact,
        data: build_data_payload,
        android: build_android_config,
        apns: build_apns_config
      }
    }
  end

  def build_data_payload
    {
      notification_id: @notification.id.to_s,
      link: @notification.link,
      type: @notification.type,
      created_at: @notification.created_at.iso8601
    }.compact.transform_values(&:to_s)
  end

  def build_android_config
    {
      priority: "high",
      notification: {
        icon: "ic_notification",
        color: "#FF6B35",
        sound: "default",
        click_action: @notification.link
      }.compact
    }
  end

  def build_apns_config
    {
      headers: {
        "apns-priority" => "10"
      },
      payload: {
        aps: {
          alert: {
            title: @notification.title,
            body: @notification.content
          },
          sound: "default",
          badge: 1
        },
        custom_data: {
          notification_id: @notification.id,
          link: @notification.link
        }.compact
      }
    }
  end

  def update_notification_status
    @notification.update!(
      status: :sent,
      sent_at: Time.current
    )
  end

  def success_result
    {
      success: true,
      message: "Notification đã được gửi thành công",
      notification_id: @notification.id
    }
  end

  def error_result(message)
    {
      success: false,
      error: message,
      notification_id: @notification&.id
    }
  end
end
