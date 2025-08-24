require "net/http"
require "uri"
require "json"
require "googleauth"

class Firebase::UpdateChartDataService
  FIREBASE_BASE_URL = ENV['FIREBASE_DB_URL']

  def initialize(path:, data:)
    @path = path
    @data = data
  end

  def perform
    auth_info = get_access_token
    make_request(auth_info)
  rescue => e
    Rails.logger.error("[FirebaseUpdater] Error: #{e.message}")
    raise
  end

  private

  attr_reader :path, :data

  def get_access_token
    json_key = JSON.parse(ENV["FIREBASE_SERVICE_ACCOUNT_JSON"])
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(json_key.to_json),
      scope: ["https://www.googleapis.com/auth/firebase.database", "https://www.googleapis.com/auth/userinfo.email"]
    )
    authorizer.fetch_access_token!
    { type: :service_account, token: authorizer.access_token }
  end

  def make_request(auth_info)
    if auth_info[:type] == :secret
      uri = URI("#{FIREBASE_BASE_URL}/#{path}.json?auth=#{auth_info[:token]}")
      headers = { 'Content-Type' => 'application/json' }
    else
      uri = URI("#{FIREBASE_BASE_URL}/#{path}.json")
      headers = { 
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{auth_info[:token]}"
      }
    end

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Patch.new(uri, headers)
    request.body = data.to_json

    response = http.request(request)
    
    Rails.logger.info("[FirebaseUpdater] #{response.code}: #{response.body}")
    response
  end
end
