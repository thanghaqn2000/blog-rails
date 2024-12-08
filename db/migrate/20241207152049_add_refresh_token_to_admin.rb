class AddRefreshTokenToAdmin < ActiveRecord::Migration[6.1]
  def change
    add_column :admins, :refresh_token, :string
  end
end
