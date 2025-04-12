class Api::V1::UsersController < Api::V1::BaseController
  before_action :user, only: :update

  def create
    user = User.new(user_params)
    if user.save
      response_api({message: "User created successfully"}, :created)
    else
      response_api({errors: user.errors.messages}, :bad_request)
    end
  end

  def update
    update_attributes = user_params.to_h

    if params[:user][:current_password].present?
      unless user.valid_password?(params[:user][:current_password])
        return response_api({ errors: { current_password: ["Mật khẩu hiện tại không đúng"] } }, :bad_request)
      end
    else
      update_attributes.delete(:password)
    end

    if user.update(update_attributes)
      response_api({user: UserSerializer.new(user)}, :ok)
    else
      response_api({ errors: user.errors.messages }, :bad_request)
    end
  end

  def check_info_uniqueness
    [:email, :phone_number].each do |attr|
      next unless params[attr].present?

      value = params[attr]
      title = attr == :email ? "Email" : "Số điện thoại"

      if User.exists?(attr => value)
        return response_api({ errors: "#{title} này đã được sử dụng", field: attr }, :bad_request, code: 410)
      else
        return response_api({ message: "#{title} chưa được sử dụng" }, :ok)
      end
    end

    response_api({ errors: "Email hoặc số điện thoại không được để trống" }, :bad_request)
  end


  def verify_social_token
    access_token = params[:access_token]
    raise Api::ParamInvalid, "Access token không được để trống" if access_token.blank?

    begin
      decoded_data = decode_social_token(access_token)
      user = find_or_create_user(decoded_data)
      generate_auth_response(user)
    rescue JWT::ExpiredSignature
      response_api({ errors: "Token đã hết hạn" }, :unauthorized)
    rescue JWT::DecodeError
      response_api({ errors: "Token không hợp lệ" }, :unauthorized)
    rescue StandardError => e
      response_api({ errors: "Có lỗi xảy ra: #{e.message}" }, :internal_server_error)
    end
  end

  private
  def user
    @user ||= User.find_by(id: params[:id])
    return @user if @user

    response_api({ errors: "Không tìm thấy người dùng" }, :not_found) and return
  end

  def user_params
    params.required(:user).permit :name, :email, :password, :phone_number
  end

  def decode_social_token(access_token)
    decoded_token = JWT.decode(access_token, nil, false, { algorithm: 'none' }).first.transform_keys(&:to_sym)
    verify_expiration_token(decoded_token)
    decoded_token
  end

  def find_or_create_user(decoded_data)
    user_data = decoded_data[:user_metadata].transform_keys(&:to_sym)

    begin
      User.transaction(requires_new: true) do
        user = User.find_by(email: user_data[:email])
        return user if user.present?

        User.new(
        email: user_data[:email],
        name: user_data[:full_name],
        password: ENV['DEFAULT_PASSWORD']
      ).tap { |u| u.save!(validate: false) }
    end
    rescue ActiveRecord::RecordNotUnique
      User.find_by(email: user_data[:email])
    end
  end

  def generate_auth_response(user)
    resource = { resource: user}
    response_data = Api::GenerateAccessTokenService.new(resource).perform
    refresh_token = Api::GenerateRefreshTokenService.new(user).perform
    cookies.signed[:refresh_token] = {
      value: refresh_token,
      **COOKIE_OPTIONS
    }
    response_api(response_data, :ok)
  end

  def verify_expiration_token(decoded_token)
    raise JWT::ExpiredSignature if decoded_token[:exp].to_i < Time.current.to_i
  end
end
