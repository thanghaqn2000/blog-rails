class ApplicationController < ActionController::Base
  include Pagination

  skip_forgery_protection
  before_action :authorize_request!
  before_action :configure_permitted_parameters, if: :devise_controller?
  rescue_from Api::Error, with: :handle_api_error

  private
  def authorize_request!
    authorization_header = request.headers[Settings.authorization.header]
    raise Api::Unauthorized, "Account or password is invalid" unless authorization_header

    resource_type = request.path.split("/")[2] == "admin" ? "admin" : "user"
    instance_variable_set "@current_#{resource_type}",
                          Api::AuthorizeRequestService.new(
                            authorization_header: authorization_header,
                            resource_type: resource_type
                          ).perform
  end

  def handle_api_error exception
    error_hash = exception.to_hash
    render json: error_hash, status: error_hash[:status]
  end

  def response_api body, status, code: nil
    code ||=  Rack::Utils::SYMBOL_TO_STATUS_CODE[status]
    render json: { data: body, code: code }, status: status
  end

  def configure_permitted_parameters
    if resource_class == Admin
      devise_parameter_sanitizer.permit(:sign_in, keys: [:email])
      devise_parameter_sanitizer.permit(:sign_up, keys: [:email])
      devise_parameter_sanitizer.permit(:account_update, keys: [:email])
    elsif resource_class == User
      devise_parameter_sanitizer.permit(:sign_in, keys: [:phone_number])
      devise_parameter_sanitizer.permit(:sign_up, keys: [:phone_number])
      devise_parameter_sanitizer.permit(:account_update, keys: [:phone_number])
    end
  end
end
