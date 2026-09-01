class RemovePaymentStatusFromLessons < ActiveRecord::Migration[8.1]
  def change
    remove_column :lessons, :payment_status, :string, default: "unpaid" if column_exists?(:lessons, :payment_status)
    remove_column :lessons, :cancellation_fee_currency, :string if column_exists?(:lessons, :cancellation_fee_currency)
  end
end
