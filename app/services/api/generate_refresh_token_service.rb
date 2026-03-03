class Api::GenerateRefreshTokenService
  def initialize(resource, request: nil)
    @resource = resource
    @resource_type = resource.class.name
    @request = request
  end

  def perform
    @device_limit_exceeded = false
    RefreshToken.transaction do
      @device_limit_exceeded = RefreshToken.enforce_max_sessions!(resource)
      generate_refresh_token
    end
    raw_token
  end

  def device_limit_exceeded?
    @device_limit_exceeded
  end

  private

  attr_reader :resource, :resource_type, :raw_token, :request

  def payload
    {
      resource_type: resource_type,
      id: resource.id,
      type: 'refresh'
    }
  end

  def generate_refresh_token
    expires_in_weeks = Settings.token.refresh.expires_in_weeks.to_i
    expires_at = Time.now + expires_in_weeks.weeks

    @raw_token = JsonWebToken.encode(payload, expires_at)

    resource.refresh_tokens.create!(
      token_digest: RefreshToken.digest(@raw_token),
      expires_at: expires_at,
      user_agent: request&.user_agent,
      ip_address: request&.remote_ip
    )

    # Đồng bộ cột cũ (backward compatible, xóa sau khi cleanup)
    resource.update_columns(refresh_token: @raw_token)
  end
end
