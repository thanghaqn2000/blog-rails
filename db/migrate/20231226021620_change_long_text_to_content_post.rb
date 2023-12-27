class ChangeLongTextToContentPost < ActiveRecord::Migration[6.1]
  def change
    change_column :posts, :content, :longtext
  end
end
