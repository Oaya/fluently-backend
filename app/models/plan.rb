class Plan < ApplicationRecord
  has_many :tenants

  validates :name, presence: true, on: :create
  validates :price, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :price_input_is_integer

  private

  def price_input_is_integer
    raw = price_before_type_cast
    return if raw.nil? || raw.to_s.empty?
    return if raw.is_a?(Integer)
    errors.add(:price, :not_an_integer) if raw.is_a?(Float) || raw.to_s.include?(".")
  end
end
