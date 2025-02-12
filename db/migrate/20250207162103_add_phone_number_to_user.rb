class AddPhoneNumberToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :phone_number, :string, after: :date_of_birth
    rename_column :users, :user_name, :name
  end
end
