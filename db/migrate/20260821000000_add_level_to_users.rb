class AddLevelToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :language_levels, :jsonb, default: []
  end
end
