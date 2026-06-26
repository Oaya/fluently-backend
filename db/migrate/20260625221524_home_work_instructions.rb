class HomeWorkInstructions < ActiveRecord::Migration[8.1]
  def change
    add_column :homeworks, :instructions, :string
  end
end
