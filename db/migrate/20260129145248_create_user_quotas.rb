class CreateUserQuotas < ActiveRecord::Migration[7.1]
  def change
    create_table :user_quotas, id: false do |t|
      t.bigint :user_id, null: false, primary_key: true
      t.integer :daily_limit, default: 0, null: false
      t.integer :used_today, default: 0, null: false
      t.datetime :reset_at

      t.timestamps
    end

    add_foreign_key :user_quotas, :users, column: :user_id
    add_index :user_quotas, :reset_at
  end
end
