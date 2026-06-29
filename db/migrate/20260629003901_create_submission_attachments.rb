class CreateSubmissionAttachments < ActiveRecord::Migration[8.1]
  def change
    create_table :submission_attachments, id: :uuid do |t|
      t.references :homework_submission, type: :uuid, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :url

      t.timestamps
    end
  end
end
