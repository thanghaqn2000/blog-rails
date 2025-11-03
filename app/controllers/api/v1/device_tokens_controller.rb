class Api::V1::DeviceTokensController < Api::V1::BaseController
  # POST /api/v1/device_tokens/register
  def register_token
    mock_user = User.find_by(id: 4)
    begin
      device_token = mock_user.register_device_token(
        token: params[:token],
        device_id: params[:deviceId], 
        platform: params[:platform]
      )
      response_api({        message: "Device token đã được đăng ký thành công",
        device_token: {
          id: device_token.id,
          device_id: device_token.device_id,
          platform: device_token.platform,
          active: device_token.active
        }
      }, :ok)

    rescue ActiveRecord::RecordInvalid => e
      response_api({
        errors: e.record.errors.full_messages
      }, :bad_request)
    rescue => e
      response_api({
        errors: "Có lỗi xảy ra: #{e.message}"
      }, :internal_server_error)
    end
  end

  # DELETE /api/v1/device_tokens/:device_id
  def unregister_token
    device_token = current_user.device_tokens.find_by(device_id: params[:device_id])
    
    if device_token
      device_token.deactivate!
      response_api({
        message: "Device token đã được hủy đăng ký"
      }, :ok)
    else
      response_api({
        errors: "Không tìm thấy device token"
      }, :not_found)
    end
  rescue => e
    response_api({
      errors: "Có lỗi xảy ra: #{e.message}"
    }, :internal_server_error)
  end

  # GET /api/v1/device_tokens
  def index
    device_tokens = current_user.active_device_tokens
    
    response_api({
      device_tokens: device_tokens.map do |token|
        {
          id: token.id,
          device_id: token.device_id,
          platform: token.platform,
          active: token.active,
          created_at: token.created_at
        }
      end
    }, :ok)
  end

  private

  def authenticate_user!
    unless current_user
      response_api({
        errors: "Bạn cần đăng nhập để sử dụng chức năng này"
      }, :unauthorized)
    end
  end

  def device_token_params
    params.permit(:token, :device_id, :platform)
  end
end
