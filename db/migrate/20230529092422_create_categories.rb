class CreateCategories < ActiveRecord::Migration[6.1]
  def change
    create_table :categories, id: false do |t|
      t.primary_key :id, unsigned: true, null: false, auto_increment: true
      t.string :name
      t.datetime :deleted_at
      t.timestamps
    end
  end
end
