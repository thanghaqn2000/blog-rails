class TopStocks::UploadDataService
  def initialize(data)
    @raw_data = data || {}
    @top_stocks_data = @raw_data['top_stocks'] || @raw_data[:top_stocks]
    @setting_data = @raw_data['setting_stock_insight'] || @raw_data[:setting_stock_insight]
  end

  def call
    return validation_error('Không có dữ liệu top_stocks') if @top_stocks_data.blank?
    return validation_error('Không có dữ liệu setting_stock_insight') if @setting_data.blank?

    top_stock_records = []
    errors = []

    @top_stocks_data.each_with_index do |item, index|
      params = build_top_stock_params(item)
      record = TopStock.new(params)

      if record.valid?
        top_stock_records << params
      else
        errors << "Dòng #{index + 1}: #{record.errors.full_messages.join(', ')}"
      end
    end

    return validation_error('Có lỗi trong dữ liệu top_stocks', errors) if errors.any?

    setting_params = build_setting_params(@setting_data)

    save_records(top_stock_records, setting_params)
  end

  private
  def build_top_stock_params(item)
    symbol    = item['symbol'] || item[:symbol]
    rs_value  = item['rs_value'] || item[:rs_value]
    vol_20d   = item['vol_20d'] || item[:vol_20d]
    rank      = item['rank'] || item[:rank]

    {
      rank: rank,
      symbol: symbol&.to_s,
      rs_value: rs_value&.to_s,
      vol_20d: vol_20d&.to_s,
    }
  end

  def build_setting_params(data)
    {
      date:            data['date'] || data[:date],
      advancing:       data['advancing'] || data[:advancing],
      declining:       data['declining'] || data[:declining],
      pct_above_ma50:  data['pct_above_ma50'] || data[:pct_above_ma50],
      pct_above_ma100: data['pct_above_ma100'] || data[:pct_above_ma100],
      pct_above_ma200: data['pct_above_ma200'] || data[:pct_above_ma200],
      vnindex_close:   data['vnindex_close'] || data[:vnindex_close],
      vnindex_ma200:   data['vnindex_ma200'] || data[:vnindex_ma200],
      index_pct:       data['index_pct'] || data[:index_pct],
      signal_ma200:    data['signal_ma200'] || data[:signal_ma200],
      signal_breadth:  data['signal_breadth'] || data[:signal_breadth],
      signal_ma50:     data['signal_ma50'] || data[:signal_ma50],
      market_regime:   data['market_regime'] || data[:market_regime],
    }
  end

  def save_records(top_stock_records, setting_params)
    TopStock.transaction do
      TopStock.destroy_all
      TopStock.create!(top_stock_records)

      SettingStockInsight.destroy_all
      SettingStockInsight.create!(setting_params)
    end

    # Update Firebase sau khi DB transaction thành công
    # Nếu Firebase fail, không rollback DB (đã save thành công)
    begin
      update_firebase_timestamp
    rescue StandardError => e
      Rails.logger.warn("Firebase update failed: #{e.message}")
      # Không raise - DB đã save thành công, chỉ log warning
    end

    success_result(top_stock_records.length)
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

