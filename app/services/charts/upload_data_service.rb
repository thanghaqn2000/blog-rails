class Charts::UploadDataService
  def initialize(chart_data)
    @chart_data = chart_data
  end

  def call
    return validation_error if @chart_data.blank?

    charts_to_create = []
    errors = []

    @chart_data.each_with_index do |item, index|
      chart_params = build_chart_params(item)
      chart = Chart.new(chart_params)
      
      if chart.valid?
        charts_to_create << chart_params
      else
        errors << "Dòng #{index + 1}: #{chart.errors.full_messages.join(', ')}"
      end
    end

    return validation_error('Có lỗi trong dữ liệu', errors) if errors.any?

    save_charts(charts_to_create)
  end

  private

  def build_chart_params(item)
    {
      rank: item['rank']&.to_s,
      name: item['name'],
      price: item['price']&.to_s
    }
  end

  def save_charts(charts_to_create)
    Chart.transaction do
      Chart.destroy_all
      Chart.create!(charts_to_create)
      update_firebase_timestamp
    end

    success_result(charts_to_create.length)
  rescue ActiveRecord::RecordInvalid => e
    error_result('Lỗi khi lưu dữ liệu vào database', :unprocessable_entity, e.message)
  end

  def update_firebase_timestamp
    Firebase::UpdateChartDataService.new(
      path: "charts/last_updated_at", 
      data: { last_updated_at: Time.current.to_s }
    ).perform
  end

  def success_result(total_records)
    {
      success: true,
      message: 'Upload dữ liệu thành công',
      total_records: total_records
    }
  end

  def error_result(error, status = :unprocessable_entity, details = nil)
    result = { success: false, error: error, status: status }
    result[:details] = details if details
    result
  end

  def validation_error(error = 'Không có dữ liệu để xử lý', details = nil)
    error_result(error, :bad_request, details)
  end
end
