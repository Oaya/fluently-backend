class Lesson < ApplicationRecord
  belongs_to :student, class_name: "User"
  belongs_to :admin,   class_name: "User"
  has_one :lesson_recording, dependent: :destroy
  has_one :invoice, dependent: :destroy
  after_create :set_room_name

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
  validates :meeting_duration_in_seconds, numericality: { greater_than: 0, only_integer: true }, allow_nil: true


  private

  def set_room_name
    update_column(:room_name, "lesson-#{id}")
  end
end
