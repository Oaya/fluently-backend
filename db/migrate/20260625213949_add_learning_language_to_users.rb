class AddLearningLanguageToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :learning_language, :string, array: true, default: []
  end
end
