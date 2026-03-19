class AddAuthorTypeAndSourceToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :author_type, :integer, default: 0, null: false
    add_column :posts, :source, :string
  end
end

