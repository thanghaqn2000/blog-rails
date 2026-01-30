class AddStatusToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :status, :string, default: 'success', null: false
    add_index :messages, :status
  end
end
