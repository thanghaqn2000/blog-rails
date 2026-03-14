class CreateFeedbacks < ActiveRecord::Migration[7.1]
  def change
    create_table :feedbacks do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.string :page_issue
      t.text :image_url
      t.string :image_key
      t.integer :status, default: 0, null: false
      t.string :phone_number

      t.references :user, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
