class Lesson < ApplicationRecord
  belongs_to :tenant
  belongs_to :section
  has_one_attached :video

  validates :title, presence: true, on: :create
  validates :lesson_type, presence: true, on: :create
  validates :position, presence: true, numericality: { only_integer: true }, uniqueness: { scope: :section_id }
  validate :video_validation


  enum :lesson_type, {
    video: "video",
    reading: "reading"
  }


  before_validation :assign_position, on: :create
  after_destroy :move_positions

  private

  # Auto assign the position when it's created
  def assign_position
    return if position.present?
    return if section_id.nil?

    self.position ||= Lesson.where(section_id: section_id)
    .maximum(:position).to_i + 1
  end

  def move_positions
    return if position.nil?

    Lesson.where(section_id: section_id).where("position > ?", position).update_all("position = position - 1")
  end

  def video_validation
    return unless lesson_type == "video" || video.attached?

    allowed = [ "video/mp4", "video/webm", "video/ogg" ]

    unless allowed.include?(video.content_type)
      errors.add(:video, "must be a valid video format (mp4, webm, ogg)")
    end

    if video.byte_size > 500.megabytes
      errors.add(:video, "size must be less than 500MB")
    end
  end
end
