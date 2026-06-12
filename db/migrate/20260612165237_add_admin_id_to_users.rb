class AddAdminIdToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :admin_id, :uuid
  end
end
