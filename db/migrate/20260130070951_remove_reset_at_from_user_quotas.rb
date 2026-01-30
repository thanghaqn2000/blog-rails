class RemoveResetAtFromUserQuotas < ActiveRecord::Migration[7.1]
  def change
    remove_column :user_quotas, :reset_at, :datetime
  end
end
