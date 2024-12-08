class Api::GenerateAccessTokenService
  def initialize args
    @resource = args[:resource]
    @refresh_token = args[:refresh_token]
    @resource_type = resource.class.name
  end

  def perform
    @expired_at = Time.now + (Settings.token.access.expires_in_hours.to_i).hour
    @access_token = generate_access_token
    response
  end

  private
  attr_reader :resource, :resource_type

  def payload
    {
      resource_type: resource_type,
      id: resource.id,
      type: 'access'
    }
  end

  def generate_access_token
    JsonWebToken.encode(
      payload,
      @expired_at
    )
  end

  def response
    {
      token_info: {
        access_token: @access_token,
        refresh_token: @refresh_token,
        expired_at: @expired_at
      },
      "#{resource_type.downcase}": resource
    }
  end
end
