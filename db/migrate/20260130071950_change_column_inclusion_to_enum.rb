class ChangeColumnInclusionToEnum < ActiveRecord::Migration[7.1]
  def change
    change_column :conversations, :status, :integer, default: 0, null: false
    change_column :messages, :role, :integer, default: 0, null: false
    change_column :messages, :status, :integer, default: 0, null: false
  end
end
