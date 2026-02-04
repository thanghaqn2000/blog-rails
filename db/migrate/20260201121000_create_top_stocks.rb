class CreateTopStocks < ActiveRecord::Migration[7.1]
  def change
    create_table :top_stocks do |t|
      t.integer :rank
      t.string :symbol
      t.decimal :rs_value, precision: 10, scale: 2
      t.decimal :vol_20d, precision: 10, scale: 2

      t.timestamps
    end
  end
end

