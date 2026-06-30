class RemoveHwColumn < ActiveRecord::Migration[8.1]
  def change
    remove_column "homeworks", "reviewed_at", :date
    remove_column "homeworks", "status", :string
    remove_column "homeworks", "submitted_at", :date

    add_column "submission_attachments", "sub", :string
  end
end
