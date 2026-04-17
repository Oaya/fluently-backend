class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :course
  belongs_to :tenant

  enum :status, { enrolled: "enrolled", in_progress: "in_progress", completed: "completed" }
end
