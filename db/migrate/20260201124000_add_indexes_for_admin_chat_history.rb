class AddIndexesForAdminChatHistory < ActiveRecord::Migration[7.1]
  def change
    add_index :conversations, [:user_id, :created_at], order: { created_at: :desc }
    add_index :messages, [:conversation_id, :created_at], order: { created_at: :asc }
  end
end

