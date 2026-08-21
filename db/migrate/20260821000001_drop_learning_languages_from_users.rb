class DropLearningLanguagesFromUsers < ActiveRecord::Migration[8.0]
  def up
    # Migrate existing data into language_levels before dropping
    User.find_each do |user|
      next if user.learning_languages.blank?
      next if user.language_levels.present?

      user.update_columns(
        language_levels: user.learning_languages.map { |lang| { language: lang, level: nil } }
      )
    end

    remove_column :users, :learning_languages
  end

  def down
    add_column :users, :learning_languages, :string, array: true, default: []

    User.find_each do |user|
      next if user.language_levels.blank?

      user.update_columns(
        learning_languages: user.language_levels.map { |ll| ll["language"] }.compact
      )
    end
  end
end
