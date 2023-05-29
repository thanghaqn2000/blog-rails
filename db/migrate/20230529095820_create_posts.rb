class CreatePosts < ActiveRecord::Migration[6.1]
  def change
    create_table :posts, id: false do |t|
      t.primary_key :id, unsigned: true, null: false, auto_increment: true
      t.string :title
      t.text :content
      t.references :admin, unsigned: true
      t.references :category, unsigned: true
      t.datetime :deleted_at
      t.timestamps
    end
  end
end
