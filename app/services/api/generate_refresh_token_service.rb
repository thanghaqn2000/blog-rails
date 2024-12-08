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
    @raw_token = JsonWebToken.encode(
      payload,
      2.weeks.from_now
    )
    resource.update! refresh_token: raw_token
  end
end
