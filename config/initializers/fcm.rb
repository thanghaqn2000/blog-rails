# Firebase Cloud Messaging Configuration
# 
# Có 2 cách authentication:
#
# 1. Service Account (Khuyên dùng):
# - FIREBASE_PROJECT_ID: Your Firebase project ID
# - FIREBASE_SERVICE_ACCOUNT_JSON: JSON string of your service account credentials
#
# 2. Server Key (Legacy - sắp deprecated):
# - FCM_SERVER_KEY: Your FCM server key
#
# Example of FIREBASE_SERVICE_ACCOUNT_JSON:
# {
#   "type": "service_account",
#   "project_id": "your-project-id",
#   "private_key_id": "...",
#   "private_key": "...",
#   "client_email": "...",
#   "client_id": "...",
#   "auth_uri": "https://accounts.google.com/o/oauth2/auth",
#   "token_uri": "https://oauth2.googleapis.com/token",
#   "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
#   "client_x509_cert_url": "..."
# }

unless Rails.env.test?
  # Validate Firebase Project ID
  if ENV['FIREBASE_PROJECT_ID'].blank?
    Rails.logger.error("[FCM] FIREBASE_PROJECT_ID environment variable is not set. Push notifications will not work.")
  else
    Rails.logger.info("[FCM] Firebase Project ID: #{ENV['FIREBASE_PROJECT_ID']}")
  end

  # Validate Firebase Service Account JSON
  if ENV['FIREBASE_SERVICE_ACCOUNT_JSON'].blank?
    Rails.logger.error("[FCM] FIREBASE_SERVICE_ACCOUNT_JSON environment variable is not set. Push notifications will not work.")
  else
    # Validate JSON format
    begin
      service_account = JSON.parse(ENV['FIREBASE_SERVICE_ACCOUNT_JSON'])
      required_fields = ['type', 'project_id', 'private_key', 'client_email']
      missing_fields = required_fields - service_account.keys
      
      if missing_fields.any?
        Rails.logger.error("[FCM] FIREBASE_SERVICE_ACCOUNT_JSON is missing required fields: #{missing_fields.join(', ')}")
      else
        Rails.logger.info("[FCM] Firebase Service Account configured for project: #{service_account['project_id']}")
      end
    rescue JSON::ParserError => e
      Rails.logger.error("[FCM] FIREBASE_SERVICE_ACCOUNT_JSON contains invalid JSON: #{e.message}")
    end
  end
end
