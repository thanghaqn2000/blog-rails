class Api::Admin::RefreshTokensController < Api::Admin::BaseController
  skip_before_action :authorize_request!
  before_action :authorize_refresh_request!

  def create
    refresh_token = Api::GenerateRefreshTokenService.new(@admin, request: request).perform
    params = { resource: @admin, refresh_token: refresh_token }
    render json: Api::GenerateAccessTokenService.new(params).perform
  end

  private

  def authorize_refresh_request!
    raw_token = params[:refresh_token]
    raise Api::ParamInvalid, "Invalid refresh token" if raw_token.blank?

    # Tìm trong bảng refresh_tokens mới (ưu tiên)
    token_record = RefreshToken.find_active_by_raw_token(raw_token)

    if token_record
      @admin = token_record.user
    else
      # Fallback: tìm trong cột cũ (backward compatible)
      decoded_token = JsonWebToken.decode(raw_token)
      raise Api::ParamInvalid, "Invalid refresh token" if decoded_token[:type] != 'refresh'
      @admin = User.find_by(refresh_token: raw_token)
    end

    raise Api::Unauthorized, "Phiên đăng nhập đã hết hạn" if @admin.blank?
    raise Api::Unauthorized, "Unauthorized access" unless @admin.admin?
  rescue JWT::DecodeError, JWT::ExpiredSignature
    raise Api::Unauthorized, "Refresh token không hợp lệ hoặc đã hết hạn"
  end
end
