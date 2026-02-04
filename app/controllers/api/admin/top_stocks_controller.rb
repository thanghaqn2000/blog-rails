class Api::Admin::TopStocksController < Api::Admin::BaseController
  def upload_data
    result = TopStocks::UploadDataService.new(params[:data]).call

    if result[:success]
      render_success(result[:message], result[:total_records])
    else
      render_error(result[:error], result[:status], result[:details])
    end
  rescue StandardError => e
    render_error('Có lỗi xảy ra khi xử lý dữ liệu', :internal_server_error, e.message)
  end

  def index
    top_stocks = TopStock.all

    render_paginated(top_stocks, serializer: TopStockSerializer)
  end
end

