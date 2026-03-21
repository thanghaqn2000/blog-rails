class Api::V1::TopStocksController < Api::V1::BaseController
  def index
    top_stocks =
      if current_user.nil? || current_user.user?
        last_two_ids = TopStock.order(rank: :desc).limit(2).pluck(:id)
        TopStock.where(id: last_two_ids).order(rank: :asc)
      else
        TopStock.order(rank: :asc)
      end

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

