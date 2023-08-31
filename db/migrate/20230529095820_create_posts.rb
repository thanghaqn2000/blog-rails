class CreatePosts < ActiveRecord::Migration[6.1]
  def change
    create_table :posts, id: false do |t|
      t.primary_key :id, unsigned: true, null: false, auto_increment: true
      t.string :title
      t.text :content
      t.integer :category, default: 0
      t.references :admin, unsigned: true
      t.datetime :deleted_at
      t.timestamps
    end
  end
end
