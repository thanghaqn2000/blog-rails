class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users, id: false do |t|
      t.primary_key :id, unsigned: true, null: false, auto_increment: true
      t.string :user_name
      t.string :email
      t.string :password
      t.date :date_of_birth
      t.datetime :deleted_at
      t.timestamps
    end
  end
end
