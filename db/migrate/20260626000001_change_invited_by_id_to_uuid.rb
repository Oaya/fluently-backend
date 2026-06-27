class ChangeInvitedByIdToUuid < ActiveRecord::Migration[8.0]
  def up
    remove_index :users, name: "index_users_on_invited_by_id", if_exists: true
    remove_index :users, name: "index_users_on_invited_by", if_exists: true

    execute "UPDATE users SET invited_by_id = NULL WHERE invited_by_id::text NOT SIMILAR TO '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'"

    change_column :users, :invited_by_id, :uuid, using: "invited_by_id::text::uuid"

    add_index :users, :invited_by_id, name: "index_users_on_invited_by_id"
    add_index :users, [ :invited_by_type, :invited_by_id ], name: "index_users_on_invited_by"
  end

  def down
    remove_index :users, name: "index_users_on_invited_by_id", if_exists: true
    remove_index :users, name: "index_users_on_invited_by", if_exists: true

    change_column :users, :invited_by_id, :bigint, using: "NULL"

    add_index :users, :invited_by_id, name: "index_users_on_invited_by_id"
    add_index :users, [ :invited_by_type, :invited_by_id ], name: "index_users_on_invited_by"
  end
end
