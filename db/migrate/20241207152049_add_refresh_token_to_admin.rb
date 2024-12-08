class AddRefreshTokenToAdmin < ActiveRecord::Migration[6.1]
  def change
    add_column :admins, :refresh_token, :string, limit: 255, null: true
    add_index :admins, :refresh_token, unique: true, where: "refresh_token IS NOT NULL"
  end
end