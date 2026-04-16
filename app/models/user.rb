class User < ApplicationRecord
  include Filterable

  attr_accessor :invited_courses

  belongs_to :tenant
  has_one :membership, dependent: :destroy
  has_one_attached :avatar
  has_many :enrollments

  validates :first_name, :last_name, :email, :tenant_id, presence: true
  validates :email, uniqueness: { case_sensitive: false }
  validates :status, presence: true

  # # Add scopes for filters
  scope :filter_by_status, ->(status) do
    status.present? ? where(status: status.split(",")) : all
  end

  scope :filter_by_role, ->(role) {
    role.present? ? joins(:membership).where(memberships: { role: role.split(",") }) : all
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


  # This add devise api with users
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
