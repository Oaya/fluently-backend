class Course < ApplicationRecord
  belongs_to :tenant
  has_many :sections, dependent: :destroy
  has_many :course_instructors, dependent: :destroy
  has_many :instructors, through: :course_instructors, source: :instructor
  has_many :enrollments
  has_one_attached :thumbnail

  validates :title, presence: true, on: :create
  validates :description, presence: true, on: :create
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :thumbnail_validation


  enum :category, {
   development: "Development",
    business: "Business",
    finance: "Finance",
    it_software: "IT & Software",
    design: "Design",
    marketing: "Marketing",
    lifestyle: "Lifestyle",
    personal_development: "Personal Development",
    photography: "Photography",
    health_fitness: "Health & Fitness",
    music: "Music",
    teaching_academics: "Teaching & Academics"
  }

  enum :level, {
    beginner: "Beginner",
    intermediate: "Intermediate",
    advanced: "Advanced",
    all_levels: "All Levels"
  }

  private

  def thumbnail_validation
    return unless thumbnail.attached?

    allowed = [ "image/jpeg", "image/png", "image/gif", "image/webp" ]

    unless allowed.include?(thumbnail.blob.content_type)
      errors.add(:thumbnail, "must be a JPEG, PNG, GIF, or WEBP image")
    end

    if thumbnail.byte_size > 5.megabytes
      errors.add(:thumbnail, "size must be less than 5MB")
    end
  end
end
