class Api::GenerateRefreshTokenService
  def initialize resource
    @resource = resource
    @resource_type = resource.class.name
  end

  def perform
    generate_refresh_token
    raw_token
  end

  private
  attr_reader :resource, :resource_type, :raw_token

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
    @raw_token = JsonWebToken.encode(
      payload,
      expires_at
    )
    resource.update_columns(refresh_token: raw_token)
  end
end
