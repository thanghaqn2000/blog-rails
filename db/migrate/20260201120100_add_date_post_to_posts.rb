# frozen_string_literal: true

class AddDatePostToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :date_post, :date
  end
end
