class Api::Admin::RefreshTokensController < Api::Admin::BaseController
  skip_before_action :authorize_request!
  skip_before_action :verify_authenticity_token
  before_action :authorize_refresh_request!

  def create
    refresh_token = Api::GenerateRefreshTokenService.new(@admin).perform
    params = {resource: @admin, refresh_token: refresh_token}
    render json: Api::GenerateAccessTokenService.new(params).perform
  end

  private

  def authorize_refresh_request!
    refresh_token = params[:refresh_token]
    raise Api::ParamInvalid, "Invalid refresh token" if refresh_token.blank?

    decoded_token = JsonWebToken.decode(refresh_token)
    raise Api::ParamInvalid, "Invalid refresh token" if decoded_token[:type] != 'refresh'

    @admin = Admin.find_by(refresh_token: refresh_token)
    raise Api::NotFound, "Not found refresh token" if @admin.blank?
  rescue JWT::DecodeError
    raise Api::ParamInvalid, "Invalid refresh token"
  end
end
