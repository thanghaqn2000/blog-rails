class CreatePosts < ActiveRecord::Migration[6.1]
  def change
    create_table :posts do |t|
      t.string  :title
      t.text    :content, limit: 16.megabytes
      t.text    :description
      t.integer :category, default: 0
      t.datetime :deleted_at
      t.integer :status, default: 0
      t.text    :image_url
      t.references :user, foreign_key: true, index: true

      t.timestamps
    end
  end
end
