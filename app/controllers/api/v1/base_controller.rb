class Api::V1::BaseController < ApplicationController
  skip_before_action :authorize_request!

  def current_user
    raw_token = cookies.signed[:refresh_token]
    return if raw_token.blank?

    # Tìm trong bảng refresh_tokens mới (ưu tiên)
    token_record = RefreshToken.find_active_by_raw_token(raw_token)
    return token_record.user if token_record

    # Fallback: cột cũ (backward compatible)
    User.find_by(refresh_token: raw_token)
  end
end
