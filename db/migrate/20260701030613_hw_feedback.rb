class HwFeedback < ActiveRecord::Migration[8.1]
  def change
    add_column :homework_submissions, :feedback, :text
    add_column :homework_submissions, :score, :string
    add_column :homework_submissions, :notes, :text
  end
end
