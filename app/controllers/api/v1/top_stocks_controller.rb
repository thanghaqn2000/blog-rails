class Api::V1::TopStocksController < Api::V1::BaseController
  def index
    top_stocks = TopStock.order(rank: :asc)

    render_paginated(top_stocks, serializer: TopStockSerializer)
  end

  def stock_insights
    insight = SettingStockInsight.first

    if insight
      render json: { data: SettingStockInsightSerializer.new(insight).as_json }
    else
      render json: { data: nil }, status: :ok
    end
  end
end

