class Api::V1::RefreshTokensController < Api::V1::BaseController
  before_action :authorize_refresh_request!

  def create
    resource = {resource: @user}
    render json: Api::GenerateAccessTokenService.new(resource).perform
  end

  private

  def authorize_refresh_request!
    refresh_token = cookies.signed[:refresh_token]
    raise Api::ParamInvalid, "Invalid refresh token" if refresh_token.blank?

    decoded_token = JsonWebToken.decode(refresh_token)
    raise Api::ParamInvalid, "Invalid refresh token" if decoded_token[:type] != 'refresh'
    @user = User.find_by(refresh_token: refresh_token)

    raise Api::NotFound, "Not found refresh token" if @user.blank?
  rescue JWT::DecodeError
    raise Api::ParamInvalid, "Invalid refresh token"
  end
end
