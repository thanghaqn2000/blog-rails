# frozen_string_literal: true

class AddSubTypeToPosts < ActiveRecord::Migration[7.1]
  def change
    add_column :posts, :sub_type, :integer, default: 0, null: false
  end
end
