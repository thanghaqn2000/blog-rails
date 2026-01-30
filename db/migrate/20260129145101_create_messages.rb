class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true, type: :bigint
      t.string :role, null: false
      t.text :content
      t.string :openai_message_id
      t.integer :token_usage, default: 0

      t.datetime :created_at, null: false
    end

    add_index :messages, :role
    add_index :messages, :openai_message_id
  end
end
