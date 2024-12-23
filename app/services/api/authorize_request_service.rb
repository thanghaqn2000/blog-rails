class Api::AuthorizeRequestService
  def initialize args
    @authorization_header = args[:authorization_header]
    @resource_class = args[:resource_type].to_s.classify
  end

    def perform
      authorize_request!
      verify_author_resource
      verify_expiration
      author_resource
    end

  private
  attr_reader :authorization_header, :resource_class, :decoded_access_token, :author_resource

  def authorize_request!
    access_token_type = authorization_header.split.first if authorization_header
    access_token = authorization_header.split.last if access_token_type == Settings.authorization.access_token_type
    @decoded_access_token = JsonWebToken.decode access_token
    raise JWT::DecodeError unless decoded_access_token[:resource_type] == resource_class
  end

  def verify_author_resource
    @author_resource = Class.const_get(resource_class).find_by id: decoded_access_token[:id]

    raise Api::Unauthorized, "Account or password is invalid" unless author_resource
  end

  def verify_expiration
    raise JWT::ExpiredSignature if decoded_access_token[:expired_at].to_i < Time.current.to_i
  end
end
