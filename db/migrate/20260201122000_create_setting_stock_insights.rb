class CreateSettingStockInsights < ActiveRecord::Migration[7.1]
  def change
    create_table :setting_stock_insights do |t|
      t.date    :date
      t.integer :advancing
      t.integer :declining
      t.decimal :pct_above_ma50,  precision: 10, scale: 4
      t.decimal :pct_above_ma100, precision: 10, scale: 4
      t.decimal :pct_above_ma200, precision: 10, scale: 4
      t.decimal :vnindex_close,   precision: 12, scale: 2
      t.decimal :vnindex_ma200,   precision: 12, scale: 2
      t.decimal :index_pct,   precision: 12, scale: 2
      t.string  :signal_ma200
      t.string  :signal_breadth
      t.string  :signal_ma50
      t.string  :market_regime

      t.timestamps
    end
  end
end

