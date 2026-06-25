class AddLearningLanguageToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :learning_language, :string
  end
end
