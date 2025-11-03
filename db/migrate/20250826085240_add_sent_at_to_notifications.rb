class AddSentAtToNotifications < ActiveRecord::Migration[7.1]
  def change
    add_column :notifications, :sent_at, :datetime
  end
end
