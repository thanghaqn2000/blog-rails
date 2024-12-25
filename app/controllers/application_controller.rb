class ApplicationController < ActionController::Base
  include Pagination

  skip_forgery_protection
  before_action :authorize_request!
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
end
