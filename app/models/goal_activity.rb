class GoalActivity < ApplicationRecord
  belongs_to :student, class_name: "User"
  belongs_to :admin,   class_name: "User"
  belongs_to :goal


  validates :description, :date, :progress, presence: true
end
