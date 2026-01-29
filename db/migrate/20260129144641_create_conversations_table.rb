class CreateConversationsTable < ActiveRecord::Migration[7.1]
  def change
    create_table :conversations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.string :openai_thread_id
      t.integer :message_count, default: 0
      t.string :status, default: 'active'

      t.timestamps
    end

    add_index :conversations, :status
    add_index :conversations, :openai_thread_id
  end
end
