class Api::V1::SessionsController < Devise::SessionsController
  respond_to :json
  skip_before_action :authorize_request!
  skip_before_action :verify_signed_out_user, only: :destroy

  def create
    response.headers['Cache-Control'] = 'no-cache, no-store'
    user = warden.authenticate!(auth_options)

    refresh_token = Api::GenerateRefreshTokenService.new(user).perform
    cookies.signed[:refresh_token] = {
      value: refresh_token,
      **COOKIE_OPTIONS
    }
    args = { resource: user, refresh_token: refresh_token }
    render json: Api::GenerateAccessTokenService.new(args).perform
  end

  def destroy
    current_user = User.find_by(refresh_token: cookies.signed[:refresh_token])
    if current_user
      begin
        current_user.update!(refresh_token: nil)
      rescue ActiveRecord::RecordInvalid => e
        return render json: { error: "Failed to logout: #{e.message}" }, status: :unprocessable_entity
      end
    end
  
    cookies.delete(:refresh_token)
  
    render json: { message: "Logged out successfully" }, status: :ok
  end
end
