class Api::Admin::BaseController < ApplicationController
  private

  def render_success(message, total_records)
    render json: {
      message: message,
      total_records: total_records
    }, status: :created
  end

  def render_error(error, status, details = nil)
    response = { error: error }
    response[:details] = details if details
    render json: response, status: status
  end
end
