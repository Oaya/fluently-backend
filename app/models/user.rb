class User < ApplicationRecord
  include Filterable

  attr_accessor :invited_courses

  has_one_attached :avatar
  has_many :enrollments, dependent: :destroy
  belongs_to :plan, optional: true

  validates :first_name, :last_name, :email, :role, presence: true
  validates :email, uniqueness: { case_sensitive: false }
  validates :status, presence: true
  validates :stripe_subscription_id, uniqueness: true, allow_nil: true
  validates :stripe_customer_id, uniqueness: true, allow_nil: true

  scope :filter_by_status, ->(status) do
    status.present? ? where(status: status.split(",")) : all
  end

  scope :filter_by_role, ->(role) {
    role.present? ? where(role: role.split(",")) : all
  }

  scope :filter_by_search, ->(value) {
    if value.present?
      pattern = "%#{sanitize_sql_like(value)}%"
      where("users.first_name LIKE :q OR users.last_name LIKE :q OR users.email LIKE :q", q: pattern)
    else
      all
    end
  }

  enum :status, {
    active: "active",
    inactive: "inactive",
    invited: "invited"
  }, validate: true

  enum :role, {
    admin: "admin",
    student: "student"
  }, validate: true

  devise :invitable,
      :database_authenticatable,
      :registerable,
      :recoverable,
      :rememberable,
      :confirmable,
      :validatable,
      :jwt_authenticatable,
      jwt_revocation_strategy: Devise::JWT::RevocationStrategies::Null
end
