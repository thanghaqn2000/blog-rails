class Api::GenerateAccessTokenService
  def initialize resource
    @resource = resource
    @resource_type = resource.class.name
  end

  def perform
    @expired_at = 1.hours.from_now
    @token = JsonWebToken.encode(payload, @expired_at)
    response
  end

  private
  attr_reader :resource, :resource_type

  def payload
    {
      resource_type: resource_type,
      id: resource.id
    }
  end

  def response
    {
      token_info: {
        access_token: @token,
        refresh_token: "",
        expired_at: @expired_at
      },
      "#{resource_type.downcase}": resource
    }
  end

  def resource_serializer
    case resource_type
    when Admin.name
      Api::Admin::AdminSerializer.new(resource, type: :admin_basic_info)
    when User.name
      Api::V1::UserSerializer.new(resource, type: :user_basic_info)
    end
  end
end
