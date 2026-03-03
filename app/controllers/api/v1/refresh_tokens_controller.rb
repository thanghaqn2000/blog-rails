class Api::V1::RefreshTokensController < Api::V1::BaseController
  before_action :authorize_refresh_request!

  def create
    resource = { resource: @user }
    render json: Api::GenerateAccessTokenService.new(resource).perform
  end

  private

  def authorize_refresh_request!
    raw_token = cookies.signed[:refresh_token]
    raise Api::ParamInvalid, "Refresh token is required" if raw_token.blank?

    # Tìm trong bảng refresh_tokens mới (ưu tiên)
    token_record = RefreshToken.find_active_by_raw_token(raw_token)

    if token_record
      @user = token_record.user
    else
      # Fallback: tìm trong cột cũ (backward compatible)
      decoded_token = JsonWebToken.decode(raw_token)
      raise Api::ParamInvalid, "Invalid refresh token" if decoded_token[:type] != 'refresh'
      @user = User.find_by(refresh_token: raw_token)
    end

    raise Api::Unauthorized, "Phiên đăng nhập đã hết hạn hoặc bị thu hồi" if @user.blank?
  rescue JWT::DecodeError, JWT::ExpiredSignature
    raise Api::Unauthorized, "Refresh token không hợp lệ hoặc đã hết hạn"
  end
end
