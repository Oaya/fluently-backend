class Tenant < ApplicationRecord
  belongs_to :plan
  belongs_to :billing_owner, class_name: "User", foreign_key: "billing_owner_id", optional: true
  has_many :courses
  has_many :sections
  has_many :lessons
  has_many :memberships
  has_many :users, through: :memberships
  has_many :enrollments

  validates :name, presence: true, uniqueness: true
  validates :plan_id, presence: true
  validates :stripe_subscription_id, uniqueness: true, allow_nil: true
  validates :stripe_customer_id, uniqueness: true, allow_nil: true

  enum :status, {
    active: "active",
    closed: "closed",
    past_due: "past_due",
    canceled: "canceled",
    pending: "pending"
  }, validate: true
end
