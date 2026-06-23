class Session < ApplicationRecord
  belongs_to :student, class_name: "User"
  belongs_to :admin,   class_name: "User"

  enum :status, {
    scheduled: "scheduled",
    completed: "completed",
    canceled: "canceled",
    no_show: "no_show"
  }, validate: true

  enum :payment_status, {
    unpaid: "unpaid",
    paid: "paid",
    refund: "refund"
  }, validate: true

  validates :scheduled_at, :status, :payment_status, presence: true
  validates :duration_in_minutes, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
end
