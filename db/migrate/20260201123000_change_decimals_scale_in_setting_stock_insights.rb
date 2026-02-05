class ChangeDecimalsScaleInSettingStockInsights < ActiveRecord::Migration[7.1]
  def up
    change_column :setting_stock_insights, :pct_above_ma50,  :decimal, precision: 20, scale: 10
    change_column :setting_stock_insights, :pct_above_ma100, :decimal, precision: 20, scale: 10
    change_column :setting_stock_insights, :pct_above_ma200, :decimal, precision: 20, scale: 10
    change_column :setting_stock_insights, :vnindex_close,   :decimal, precision: 20, scale: 10
    change_column :setting_stock_insights, :vnindex_ma200,   :decimal, precision: 20, scale: 10
    change_column :setting_stock_insights, :index_pct,       :decimal, precision: 20, scale: 10
  end

  def down
    change_column :setting_stock_insights, :pct_above_ma50,  :decimal, precision: 10, scale: 4
    change_column :setting_stock_insights, :pct_above_ma100, :decimal, precision: 10, scale: 4
    change_column :setting_stock_insights, :pct_above_ma200, :decimal, precision: 10, scale: 4
    change_column :setting_stock_insights, :vnindex_close,   :decimal, precision: 12, scale: 2
    change_column :setting_stock_insights, :vnindex_ma200,   :decimal, precision: 12, scale: 2
    change_column :setting_stock_insights, :index_pct,       :decimal, precision: 12, scale: 2
  end
end

