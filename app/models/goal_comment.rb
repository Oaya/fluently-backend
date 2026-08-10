class GoalComment < ApplicationRecord
  belongs_to :admin,   class_name: "User"
  belongs_to :goal


  validates :comment, presence: true
end
