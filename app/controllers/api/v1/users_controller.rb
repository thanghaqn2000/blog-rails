class Api::V1::UsersController < Api::V1::BaseController
  def create
    user = User.new(user_params)
  
    if user.save
      response_api({message: "User created successfully"}, :created)
    else
      response_api({errors: user.errors.messages}, :bad_request)
    end
  end

  def check_info_uniqueness
    hash_info = if params[:email]
            {
              name_attr: :email,
              value: params[:email],
              title: "Email"
            }
          elsif params[:phone_number]
            {
              name_attr: :phone_number,
              value: params[:phone_number],
              title: "Số điện thoại"
            }
          else
            response_api({ errors: "Email hoặc số điện thoại không được để trống" }, :bad_request)
            return
          end

    if User.exists?(hash_info[:name_attr] => hash_info[:value])
      response_api({errors: "#{hash_info[:title]} này đã được sử dụng"}, :bad_request, code: 410)
    else
      response_api({message: "#{hash_info[:title]} chưa được sử dụng"}, :ok)
    end
  end

  private
  def user_params
    params.required(:user).permit :name, :email, :password, :phone_number
  end
end
