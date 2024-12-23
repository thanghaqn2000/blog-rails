class Api::Admin::SessionsController < Devise::SessionsController
  respond_to :json
  skip_before_action :authorize_request!

  def create
    response.headers['Cache-Control'] = 'no-cache, no-store'
    admin = warden.authenticate!(auth_options)
    refresh_token = Api::GenerateRefreshTokenService.new(admin).perform
    args = {resource: admin, refresh_token: refresh_token}
    render json: Api::GenerateAccessTokenService.new(args).perform
  end

  def destroy
    sign_out(resource_name)
  end
end
