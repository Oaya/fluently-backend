class User < ApplicationRecord
  include Filterable

  has_one_attached :avatar
  belongs_to :plan, optional: true
  belongs_to :admin, class_name: "User", optional: true
  has_many :students, class_name: "User", foreign_key: :admin_id, dependent: :nullify
  has_many :homeworks, class_name: "Homework", foreign_key: :student_id, dependent: :destroy
  has_many :homeworks_as_admin, class_name: "Homework", foreign_key: :admin_id
  has_many :lessons_as_admin, class_name: "Lesson", foreign_key: :admin_id, dependent: :destroy
  has_many :lessons_as_student, class_name: "Lesson", foreign_key: :student_id, dependent: :destroy
  has_many :goals_as_admin, class_name: "Goal", foreign_key: :admin_id, dependent: :destroy
  has_many :goals_as_student, class_name: "Goal", foreign_key: :student_id, dependent: :destroy
  has_many :goal_activities_as_admin, class_name: "GoalActivity", foreign_key: :admin_id, dependent: :destroy
  has_many :goals_activities_as_student, class_name: "GoalActivity", foreign_key: :student_id, dependent: :destroy

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
