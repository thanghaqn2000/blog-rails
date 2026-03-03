class Api::V1::SessionsController < Devise::SessionsController
  respond_to :json
  skip_before_action :authorize_request!
  skip_before_action :verify_signed_out_user, only: :destroy

  def create
    response.headers['Cache-Control'] = 'no-cache, no-store'
    user = warden.authenticate!(auth_options)

    if params[:admin_login] && !user.admin?
      render json: { error: 'Unauthorized access' }, status: :unauthorized
      return
    end

    service = Api::GenerateRefreshTokenService.new(user, request: request)
    refresh_token = service.perform
    cookies.signed[:refresh_token] = {
      value: refresh_token,
      **COOKIE_OPTIONS
    }
    args = { resource: user, refresh_token: refresh_token }
    response_data = Api::GenerateAccessTokenService.new(args).perform
    response_data[:device_limit_exceeded] = service.device_limit_exceeded?
    render json: response_data
  end

  def destroy
    raw_token = cookies.signed[:refresh_token]

    if raw_token.present?
      # Revoke token cụ thể trong bảng mới
      token_record = RefreshToken.find_active_by_raw_token(raw_token)
      token_record&.revoke!

      # Backward compatible: clear cột cũ nếu match
      User.where(refresh_token: raw_token).update_all(refresh_token: nil)
    end

    cookies.delete(:refresh_token, **cookie_delete_options)

    render json: {
      message: "Logged out successfully",
      clear_access_token: true
    }, status: :ok
  end

  private

  def cookie_delete_options
    {
      domain: :all,
      path: '/',
      secure: Rails.env.production? || ENV['FORCE_HTTPS'] == 'true',
      same_site: (Rails.env.production? || ENV['FORCE_HTTPS'] == 'true') ? :none : :lax
    }
  end
end
