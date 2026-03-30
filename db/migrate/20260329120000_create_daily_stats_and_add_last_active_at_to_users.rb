class CreateDailyStatsAndAddLastActiveAtToUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :daily_stats do |t|
      t.date :stat_date, null: false
      t.bigint :homepage_views, null: false, default: 0
      t.bigint :top_stocks_views, null: false, default: 0
      t.bigint :new_users_count, null: false, default: 0

      t.timestamps
    end

    add_index :daily_stats, :stat_date, unique: true

    add_column :users, :last_active_at, :datetime
  end
end
