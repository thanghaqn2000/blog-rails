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

    refresh_token = Api::GenerateRefreshTokenService.new(user).perform
    cookies.signed[:refresh_token] = {
      value: refresh_token,
      **COOKIE_OPTIONS
    }
    args = { resource: user, refresh_token: refresh_token }
    render json: Api::GenerateAccessTokenService.new(args).perform
  end

  def destroy
    # Tìm và xóa refresh_token của user
    User.where(refresh_token: cookies.signed[:refresh_token])
        .update_all(refresh_token: nil)
    
    # Xóa cookie
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
