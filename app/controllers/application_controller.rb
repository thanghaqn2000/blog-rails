class ApplicationController < ActionController::Base
  rescue_from Api::Error, with: :handle_api_error

  private

  def handle_api_error exception
    error_hash = exception.to_hash
    render json: error_hash, status: error_hash[:status]
  end
end
