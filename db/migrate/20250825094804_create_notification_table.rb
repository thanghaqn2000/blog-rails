class CreateNotificationTable < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.string :title
      t.string :content
      t.string :image_url
      t.string :link
      t.integer :type, default: 0
      t.integer :status, default: 0
      t.datetime :scheduled_at
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
