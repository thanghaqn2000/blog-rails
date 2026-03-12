require "net/http"

class Api::V1::StocksController < Api::V1::BaseController
  STOCK_API_TIMEOUT = 10

  def vcb_exchange_rate
    date = params[:date]
    cache_key = "vcb_exchange_rate_#{date || Date.current.to_s}"

    data = fetch_cached(cache_key) do
      query = {}
      query[:date] = date if date.present?
      fetch_from_stock_api("/api/exchange_rates/vcb", query)
    end

    render_stock_response(data)
  end

  def gold_price_btmc
    cache_key = "gold_prices_btmc"

    data = fetch_cached(cache_key) { fetch_from_stock_api("/api/gold_prices/btmc") }

    render_stock_response(data)
  end

  def history
    symbol = sanitize_symbol(params[:symbol])
    return render json: { error: "Invalid symbol" }, status: :bad_request if symbol.blank?

    from_date = params[:from]
    to_date = params[:to]
    resolution = params[:resolution] || "1D"

    cache_key = "stock_history_#{symbol}_#{from_date}_#{to_date}_#{resolution}"

    data = fetch_cached(cache_key) do
      query = { resolution: resolution }
      query[:from] = from_date if from_date.present?
      query[:to] = to_date if to_date.present?
      fetch_from_stock_api("/api/stocks/#{symbol}/history", query)
    end

    render_stock_response(data)
  end

  private

  def sanitize_symbol(raw)
    raw.to_s.upcase.gsub(/[^A-Z0-9]/, "")
  end

  def fetch_cached(cache_key, expires_in: 60.seconds)
    data = Rails.cache.read(cache_key)
    if data.nil?
      data = yield
      Rails.cache.write(cache_key, data, expires_in: expires_in) unless error_response?(data)
    end
    data
  end

  def error_response?(data)
    data.is_a?(Hash) && data["error"]
  end

  def render_stock_response(data)
    if error_response?(data)
      render json: data, status: :service_unavailable
    elsif data.is_a?(Array)
      render_paginated_array(data)
    else
      render json: { data: data }
    end
  end

  def render_paginated_array(array)
    max_per_page = Settings.pagination.max_per_page
    per_page = [(params[:per_page] || max_per_page).to_i, max_per_page].min
    paginated = Kaminari.paginate_array(array).page(params[:page]).per(per_page)

    meta = {
      current_page: paginated.current_page,
      next_page: paginated.next_page,
      previous_page: paginated.prev_page,
      total_pages: paginated.total_pages,
      total_count: paginated.total_count
    }

    render json: { data: paginated, meta: meta }
  end

  def fetch_from_stock_api(path, query = {})
    base_url = ENV.fetch("STOCK_API_URL", "http://stock-api:8000")
    uri = URI("#{base_url}#{path}")
    uri.query = URI.encode_www_form(query) if query.present?

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = STOCK_API_TIMEOUT
    http.read_timeout = STOCK_API_TIMEOUT

    response = http.get(uri.request_uri)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("[StockAPI] HTTP #{response.code}: #{response.body}")
      parsed = JSON.parse(response.body) rescue nil
      error_msg = parsed&.dig("error") || "Stock API returned HTTP #{response.code}"
      return { "error" => error_msg }
    end

    JSON.parse(response.body)
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.error("[StockAPI] Timeout: #{e.message}")
    { "error" => "Stock API timeout" }
  rescue Errno::ECONNREFUSED => e
    Rails.logger.error("[StockAPI] Connection refused: #{e.message}")
    { "error" => "Stock API unavailable" }
  rescue JSON::ParserError => e
    Rails.logger.error("[StockAPI] Invalid JSON: #{e.message}")
    { "error" => "Failed to parse data" }
  end
end
