class Goal < ApplicationRecord
  belongs_to :student, class_name: "User"
  belongs_to :admin,   class_name: "User"
  has_many :goal_activities, dependent: :destroy
  has_many :goal_comments, dependent: :destroy

  validates :title, :target_date, presence: true

  enum :status, {
    not_started: "not_started",
    in_progress: "in_progress",
    achieved: "achieved"
  }, validate: true
end
