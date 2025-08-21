class CreateChartTable < ActiveRecord::Migration[7.1]
  def change
    create_table :charts do |t|
      t.string :rank
      t.string :name
      t.string :price

      t.timestamps
    end
  end
end
