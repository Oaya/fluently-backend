class SubmissionAttachment < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :homework_submission
  has_one_attached :file

  enum :type, { video: "video", file: "file", link: "link" }

  validates :url, presence: true, if: :link?
  validate :file_attached, if: -> { video? || file? }

  private

  def file_attached
    errors.add(:file, "must be attached") unless file.attached?
  end
end
