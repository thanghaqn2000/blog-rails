class Api::Admin::ChartsController < Api::Admin::BaseController
  skip_before_action :authorize_request!, only: [:index]

  def upload_data
    begin
      # Lấy dữ liệu từ params
      chart_data = params[:data]
      
      if chart_data.blank?
        return render json: { error: 'Không có dữ liệu để xử lý' }, status: :bad_request
      end

      # Xóa dữ liệu cũ trước khi thêm dữ liệu mới
      Chart.destroy_all

      # Tạo mảng để lưu các records mới
      charts_to_create = []
      errors = []

      chart_data.each_with_index do |item, index|
        # Chuyển đổi dữ liệu sang format phù hợp
        chart_params = {
          rank: item['rank']&.to_s,
          name: item['name'],
          price: item['price']&.to_s
        }

        # Validate dữ liệu trước khi thêm vào mảng
        chart = Chart.new(chart_params)
        if chart.valid?
          charts_to_create << chart_params
        else
          errors << "Dòng #{index + 1}: #{chart.errors.full_messages.join(', ')}"
        end
      end

      # Nếu có lỗi validation, trả về lỗi
      if errors.any?
        return render json: { 
          error: 'Có lỗi trong dữ liệu', 
          details: errors 
        }, status: :unprocessable_entity
      end

      # Tạo tất cả records cùng lúc
      Chart.create!(charts_to_create)

      render json: { 
        message: 'Upload dữ liệu thành công', 
        total_records: charts_to_create.length
      }, status: :created

    rescue ActiveRecord::RecordInvalid => e
      render json: { 
        error: 'Lỗi khi lưu dữ liệu vào database', 
        details: e.message 
      }, status: :unprocessable_entity
    rescue StandardError => e
      render json: { 
        error: 'Có lỗi xảy ra khi xử lý dữ liệu', 
        details: e.message 
      }, status: :internal_server_error
    end
  end

  def index
    charts = Chart.all

    render_paginated(charts, serializer: ChartSerializer)
  end
end
