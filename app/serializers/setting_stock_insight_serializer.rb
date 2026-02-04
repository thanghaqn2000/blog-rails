class SettingStockInsightSerializer < ActiveModel::Serializer
  attributes :id,
             :date,
             :advancing,
             :declining,
             :pct_above_ma50,
             :pct_above_ma100,
             :pct_above_ma200,
             :vnindex_close,
             :vnindex_ma200,
             :signal_ma200,
             :signal_breadth,
             :signal_ma50,
             :market_regime,
             :index_pct
end

