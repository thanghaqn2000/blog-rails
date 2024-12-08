class Api::Admin::RefreshTokensController < Api::Admin::BaseController
  before_action :authorize_refresh_request!
  skip_before_action :verify_authenticity_token

  def create
    refresh_token = Api::GenerateRefreshTokenService.new(@admin).perform
    params = {resource: @admin, refresh_token: refresh_token}
    render json: Api::GenerateAccessTokenService.new(params).perform
  end

  private

  def authorize_refresh_request!
    refresh_token = params[:refresh_token]
    @admin = Admin.find_by(refresh_token: refresh_token)
    decoded_token = JsonWebToken.decode(refresh_token)
    render json: { error: 'Invalid refresh token' }, status: :unauthorized if @admin.blank? || decoded_token[:type] != 'refresh'
  rescue JWT::DecodeError
    render json: { error: 'Invalid token' }, status: :unauthorized
  end
end
