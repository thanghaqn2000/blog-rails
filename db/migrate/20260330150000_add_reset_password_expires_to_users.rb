class AddResetPasswordExpiresToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :reset_password_expires, :datetime
    add_index :users, :reset_password_expires
  end
end

