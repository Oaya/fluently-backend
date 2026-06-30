class Homework < ApplicationRecord
  belongs_to :student, class_name: "User"
  belongs_to :admin,   class_name: "User"
  has_one :homework_submission

  validates :due_date, :title, presence: true
  validates :ai_generated, inclusion: { in: [ true, false ] }
end
