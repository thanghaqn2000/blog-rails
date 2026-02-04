class TopStockSerializer < ActiveModel::Serializer
  attributes :id, :rank, :symbol, :rs_value, :vol_20d
end

