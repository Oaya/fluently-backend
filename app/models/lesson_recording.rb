class LessonRecording < ApplicationRecord
  belongs_to :lesson

  has_one_attached :video
end
