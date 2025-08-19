class AddImageKeyForPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :image_key, :string
  end
end
