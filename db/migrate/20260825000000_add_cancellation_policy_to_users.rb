class AddCancellationPolicyToUsers < ActiveRecord::Migration[8.1]
  def change
    # Structured policy fields (percentages as integers: 0, 50, 100)
    add_column :users, :no_show_fee_percent,          :integer, default: 100
    add_column :users, :late_cancellation_fee_percent, :integer, default: 100
    # Hours before lesson that counts as "late" cancellation (0 = policy disabled)
    add_column :users, :cancellation_window_hours,     :integer, default: 24
  end
end
