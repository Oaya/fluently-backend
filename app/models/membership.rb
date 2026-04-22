class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :tenant

  # unique index on user_id and tenant_id to prevent duplicate memberships
  validates :user_id, uniqueness: { scope: :tenant_id }

  enum :role, {
    admin: "admin",
    instructor: "instructor",
    student: "student"
  }, validate: true
end
