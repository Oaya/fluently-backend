class AddLessonRate < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :lesson_rate, :decimal, precision: 10, scale: 2
    add_column :users, :currency, :string
    # Structured policy fields (percentages as integers: 0, 50, 100)
    add_column :users, :no_show_fee_percent,          :integer, default: 100
    add_column :users, :late_cancellation_fee_percent, :integer, default: 100
    # Hours before lesson that counts as "late" cancellation (0 = policy disabled)
    add_column :users, :cancellation_window_hours,     :integer, default: 24

    add_column :lessons, :cancellation_fee_amount, :decimal, precision: 10, scale: 2
    add_column :lessons, :cancellation_fee_currency, :string

    create_table :invoices, id: :uuid do |t|
      t.references :admin, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.references :student, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.references :lesson, type: :uuid, null: false, foreign_key: true

      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :currency, null: false
      t.date :due_date
      t.string :status, null: false, default: "unpaid"
      t.datetime :paid_at
      t.text :notes

      t.timestamps
    end
  end
end
