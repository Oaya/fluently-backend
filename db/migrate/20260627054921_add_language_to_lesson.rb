class AddLanguageToLesson < ActiveRecord::Migration[8.1]
  def change
    add_column :lessons, :language, :string, null: false, default: ""
  end
end
