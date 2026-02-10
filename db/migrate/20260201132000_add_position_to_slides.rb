class AddPositionToSlides < ActiveRecord::Migration[7.1]
  def change
    add_column :slides, :position, :integer, default: 0, null: false
    add_index :slides, :position
  end
end

