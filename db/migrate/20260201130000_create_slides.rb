class CreateSlides < ActiveRecord::Migration[7.1]
  def change
    create_table :slides do |t|
      t.string :heading
      t.text :description
      t.string :image_url

      t.timestamps
    end
  end
end

