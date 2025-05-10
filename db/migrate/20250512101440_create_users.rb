class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string  :name
      t.string  :email, index: { unique: true }
      t.date    :date_of_birth
      t.string  :phone_number
      t.integer :role, default: 0
      t.datetime :deleted_at
      t.string  :encrypted_password, null: false
      t.string  :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.string :refresh_token, index: { unique: true }

      t.timestamps
    end
  end
end
