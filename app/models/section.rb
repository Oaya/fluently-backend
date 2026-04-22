class Section < ApplicationRecord
  belongs_to :tenant
  belongs_to :course
  has_many :lessons, dependent: :destroy

  validates :title, presence: true, on: :create
  validates :description, presence: true, on: :create
  validates :position, presence: true, numericality: { only_integer: true }, uniqueness: { scope: :course_id }


  before_validation :assign_position, on: :create
  after_destroy :move_positions

  private

  # Auto assign the position when it's created
  def assign_position
    return if position.present?
    return if course_id.nil?

    self.position ||= Section.where(course_id: course_id)
                            .maximum(:position).to_i + 1
  end

  def move_positions
    return if position.nil?

    Section.where(course_id: course_id).where("position > ?", position).update_all("position = position - 1")
  end
end
