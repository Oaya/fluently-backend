class RemovePaymentStatusFromLessons < ActiveRecord::Migration[8.1]
  def change
    remove_column :lessons, :payment_status, :string, default: "unpaid"
    remove_column :lessons, :cancellation_fee_currency, :string
  end
end
