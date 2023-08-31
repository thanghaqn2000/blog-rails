class Api::Admin::SessionsController < Devise::SessionsController
  respond_to :json
  skip_before_action :verify_authenticity_token

  def create
    response.headers['Cache-Control'] = 'no-cache, no-store'
    admin = warden.authenticate!(auth_options)
    render json: Api::GenerateAccessTokenService.new(admin).perform
  end

  def destroy
    sign_out(resource_name)
  end

  private

  def auth_token
    JWT.encode({ user_id: current_admin.id }, Rails.application.secrets.secret_key_base)
  end
end
