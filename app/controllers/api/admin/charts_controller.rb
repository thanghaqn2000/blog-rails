class Api::Admin::ChartsController < Api::Admin::BaseController
  skip_before_action :authorize_request!, only: [:index]

  def upload_data
    result = Charts::UploadDataService.new(params[:data]).call
    
    if result[:success]
      render_success(result[:message], result[:total_records])
    else
      render_error(result[:error], result[:status], result[:details])
    end
  rescue StandardError => e
    render_error('Có lỗi xảy ra khi xử lý dữ liệu', :internal_server_error, e.message)
  end

  def index
    charts = Chart.all

    render_paginated(charts, serializer: ChartSerializer)
  end

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
