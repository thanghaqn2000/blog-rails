class CreateDeviceTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :device_tokens do |t|
      t.string :token, null: false
      t.string :device_id, null: false
      t.string :platform, null: false
      t.references :user, null: false, foreign_key: true
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :device_tokens, [:user_id, :device_id], unique: true
    add_index :device_tokens, :token
  end
end
