class ChangeBillingOwnerFkToNullify < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :tenants, column: :billing_owner_id
    add_foreign_key :tenants, :users, column: :billing_owner_id, on_delete: :nullify
  end
end
