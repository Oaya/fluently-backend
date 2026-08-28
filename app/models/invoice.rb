class Invoice < ApplicationRecord
  belongs_to :student, class_name: "User"
  belongs_to :admin,   class_name: "User"
  belongs_to :lesson

  enum :status, { unpaid: "unpaid", paid: "paid" }, validate: true

  validates :amount, presence: true, numericality: { greater_than: 0 }

  def mark_paid!
    update!(status: "paid", paid_at: Time.current)
  end
end
