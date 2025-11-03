class AddFcmTokenToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :fcm_token, :string
  end
end
