class CreateComments < ActiveRecord::Migration[6.1]
  def change
    create_table :comments, id: false do |t|
      t.primary_key :id, unsigned: true, null: false, auto_increment: true
      t.text :content
      t.references :user, unsigned: true
      t.references :category, unsigned: true
      t.datetime :deleted_at
      t.timestamps
    end
  end
end
